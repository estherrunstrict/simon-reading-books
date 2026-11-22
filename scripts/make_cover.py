#!/usr/bin/env python3
"""Turn a downloaded cover image into the site's cover file.

  python3 scripts/make_cover.py IMAGE SLUG

Writes assets/covers/<SLUG>.webp (400 px wide, for the shelf and book page)
and moves IMAGE to media/covers/<SLUG>.<ext>, where
"python3 scripts/drive_archive.py sweep --apply" uploads it to Drive
("시몬 책장/표지 원본/") and removes it from this Mac.
Prints the value for the book's front matter: cover: "/assets/covers/<SLUG>.webp"
Needs cwebp (brew install webp).
"""
import os, re, shutil, subprocess, sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))


def main():
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)
    src, slug = sys.argv[1], sys.argv[2]
    if not re.match(r"^[a-z0-9][a-z0-9-]*$", slug):
        raise SystemExit("slug must be lowercase letters, digits and -: " + slug)
    if not os.path.isfile(src):
        raise SystemExit("not a file: " + src)
    out_dir = os.path.join(ROOT, "assets", "covers")
    os.makedirs(out_dir, exist_ok=True)
    out = os.path.join(out_dir, slug + ".webp")
    r = subprocess.run(["cwebp", "-quiet", "-q", "85", "-resize", "400", "0", src, "-o", out], capture_output=True, text=True)
    if r.returncode != 0 or not os.path.getsize(out):
        raise SystemExit("cwebp failed: " + (r.stderr or r.stdout))
    keep_dir = os.path.join(ROOT, "media", "covers")
    os.makedirs(keep_dir, exist_ok=True)
    ext = os.path.splitext(src)[1].lower() or ".jpg"
    shutil.move(src, os.path.join(keep_dir, slug + ext))
    print("wrote assets/covers/%s.webp (%d KB); original waiting in media/covers/ for drive_archive sweep" % (slug, os.path.getsize(out) // 1024))
    print('cover: "/assets/covers/%s.webp"' % slug)


if __name__ == "__main__":
    main()
