#!/usr/bin/env python3
"""Make a Flow sticker image transparent around its white sticker border.

  uv run --with pillow python3 -I scripts/cutout_sticker.py IN.jpg OUT.png

Flood-fills the near-white background from the image edges, softens the edge,
crops to the sticker, and writes a PNG with alpha. Then:
  cwebp -q 86 -alpha_q 90 -resize 480 0 OUT.png -o assets/weekly/<slug>.webp
"""
import sys
from PIL import Image, ImageFilter
from collections import deque
src, dst = sys.argv[1], sys.argv[2]
im = Image.open(src).convert("RGBA")
w, h = im.size
px = im.load()
def near_white(p, t=244):
    return p[0] >= t and p[1] >= t and p[2] >= t
seen = bytearray(w*h)
q = deque()
for x in range(w):
    q.append((x,0)); q.append((x,h-1))
for y in range(h):
    q.append((0,y)); q.append((w-1,y))
bg = bytearray(w*h)
while q:
    x,y = q.popleft()
    i = y*w+x
    if seen[i]: continue
    seen[i] = 1
    if not near_white(px[x,y]): continue
    bg[i] = 1
    if x>0: q.append((x-1,y))
    if x<w-1: q.append((x+1,y))
    if y>0: q.append((x,y-1))
    if y<h-1: q.append((x,y+1))
mask = Image.frombytes("L", (w,h), bytes(0 if b else 255 for b in bg))
mask = mask.filter(ImageFilter.GaussianBlur(1.2))
im.putalpha(mask)
bbox = mask.point(lambda v: 255 if v > 8 else 0).getbbox()
im = im.crop(bbox)
im.save(dst)
print(src, im.size, sum(bg)/(w*h))
