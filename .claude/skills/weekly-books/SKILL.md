---
name: weekly-books
description: Prepare the next two books Simon chooses between on the home page - real covers and sizes from Aladin in ego lite, a cute original creature sticker and a rare collectible card illustration for each from Google Flow, written into _data/weekly.yml. Use on the Friday before a Saturday proposal, when asked "다음 주 책 준비해", "토요일 책 두 권 만들어", or when the scheduled weekly run starts.
---

# Prepare the next two books

The home page shows two books from `_data/weekly.yml`, starting on its `proposed` date (a Saturday). Simon picks one, reads it, photographs a handwritten report, and the guardian saves the book to `_books/` from the done screen. This skill prepares the next pair before that Saturday.

## 1. Is a new pair due?

Run `ruby scripts/next_pair.rb`. It prints JSON.

- `"ready": false`: the chosen book is not in `_books/` as finished yet. Stop and report the reason. Do not make a new pair.
- `"ready": true`: `books` lists the next two in order, and `proposed` is the Saturday they appear. A book with `"keep": true` is the one Simon did not pick last time; reuse its entry from `_data/weekly.yml` as it is. Make assets only for books with `"keep": false`.

## 2. Cover, size and pages (ego lite, Aladin)

Load the `ego-browser` skill and run `ego-browser skill` once. Use one TaskSpace for the whole run and `finish({ keep: [] })` at the end.

1. Search `https://www.aladin.co.kr/search/wsearchresult.aspx?SearchTarget=Book&SearchWord=<title author>` and pick the main paper edition by the same publisher as the roadmap entry. Skip e-books, sets, comics and audio.
2. On the product page read `og:image` (`cover500`), the ISBN-13, `N쪽` and the size `W*Hmm`. Aladin gives no thickness: use `round(pages * 0.06 + 2)` mm.
3. Save the cover with `page.fetch(cover, { saveAs: "/Volumes/ORICO/readcheck/media/inbox/<slug>-cover.jpg" })`, look at it with Read (front cover, not a placeholder), then
   `cwebp -q 86 media/inbox/<slug>-cover.jpg -o assets/covers/<slug>.webp` and move the original to `media/covers/<slug>.jpg`.

## 3. The creature (Google Flow)

Follow the `gflow-cli` skill's local override: drive Flow in ego lite. Use the project "시몬 책장 일러스트" (`https://flow.google.com/project/76463330-7cfe-4f21-b278-c8c3f2f01884`), Nano Banana 2.1, 1:1, x2. Note the credit count first (account button). Image generation has cost 0 credits; if Flow asks to confirm a credit spend, stop and ask the user.

Prompt, with the book's idea filled in:

> Sticker illustration of an original cute pocket-sized creature for a children's reading app, inspired by <one line about the book's main idea or hero>: <round body shape and colour that echo the cover>, <one small motif from the story>, big shiny dark eyes with white highlights, rosy cheeks. Full body, centered, standing, three-quarter view. Flat cel-shaded style with a thick clean dark navy outline and a white sticker border, soft simple shading, bright friendly colors. Plain pure white background, no text, no shadow on the ground. Completely original character design, not based on any existing game, anime or franchise character.

Pick the better of the two results. It must not look like a known franchise character; if it does, change the prompt and generate again. Open the tile (it goes to `/edit/<id>`), take the `img` with alt "읽기 전용 이미지 뷰" (1024 px), and save it with `page.fetch(src, { saveAs })` into the scratchpad. Then:

```sh
uv run --quiet --with pillow python3 -I scripts/cutout_sticker.py <in.jpg> <out.png>
cwebp -q 86 -alpha_q 90 -resize 480 0 <out.png> -o assets/weekly/<slug>.webp
```

Look at the webp with Read. Name the creature with a short original name ending in 콩 (잎콩, 퍼즐콩) that is not already used in `_data/weekly.yml` or `_books/`.

## 3b. The card illustration (Google Flow)

Each book has one collectible card (책콩 카드) that Simon gets by tearing open a pack after the report photo. Its art is a full-bleed scene with the same creature.

1. In Flow's settings set the ratio to **3:4** (keep Nano Banana 2.1, x2), then set it back to 1:1 afterwards.
2. Attach the creature sticker you just picked with "+" ("프롬프트 상자에 소재 추가" → the image → "프롬프트에 추가"), then use:

> Using the attached character exactly as it looks (same body shape, colours, face and accessories), create a full-art collectible card illustration: the character <a lively action from the book>, in <a scene from the book, with 2-3 motifs and a palette>. Joyful dynamic pose, slightly low camera angle, rich painterly background with depth, soft glowing light and tiny sparkles in the air. Keep the character in the same flat cel-shaded style with a thick dark navy outline. Vertical composition, the character fills the middle and lower two thirds, the background reaches every edge. No text, no letters, no numbers, no card frame, no border. Completely original artwork, not based on any existing game, anime or franchise.

3. Pick the result where the creature matches its sticker and sits in the middle (the card's text panel covers the bottom quarter). Download it the same way as the sticker (896 × 1200), keep the original in `media/cards/<slug>.jpg`, and
   `cwebp -q 82 -resize 720 0 media/cards/<slug>.jpg -o assets/cards/<slug>.webp`. Look at it with Read.
4. Name the card's move: 2-6 Korean words that fit the book and the creature (마당 박차기, 엉터리 돋보기).

## 4. Write _data/weekly.yml

Keep the comment header, `grade` and `grade_year`. Set `proposed` to the JSON's `proposed`. For each book write: `slug`, `title`, `author`, `publisher`, `isbn` (quoted), `pages`, `size_mm: [w, h, d]`, `cover`, `buddy`, `buddy_art`, `book_type` (이야기, 생각, 과학, 역사 or 마음), `genre` (동화, 그림책, 지식 책 ...), `tier`, `power` (from the roadmap), and `about`: one sentence in your own words, in the site's 요 tone. Never copy the publisher's description.

Then the card, nested under `card:`: `art` (`/assets/cards/<slug>.webp`), `number` (the JSON's `card_number`: the book's place in the whole roadmap), `rarity` (the JSON's `card_rarity`: SR for Must, R for Better) and `move`. Write `number`, never `no`: YAML reads `no` as false. A `keep: true` book keeps its card as it is.

## 5. Check and publish

1. `ruby scripts/check_books.rb` must pass. Build with Jekyll if it is installed and look at the home page at 820×1180.
2. Commit only `_data/weekly.yml`, `assets/covers/<slug>.webp`, `assets/weekly/<slug>.webp` and `assets/cards/<slug>.webp`.
3. Push to the branch GitHub Pages builds from only if the user turned on unattended weekly runs; otherwise report and wait for them to say so.
4. Run `python3 scripts/drive_archive.py sweep`, then with `--apply`, to move the cover and card originals to Drive.
