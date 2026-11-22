---
name: add-book
description: Add a book to Simon's reading shelf with its real cover image, found by searching an online bookstore in the user's ego lite browser. Use when the user asks to add or register a book ("책 추가해", "<제목> 책장에 꽂아", "책 등록"), pastes the line copied from the site's /add/ page, or asks to find or fix a book's cover image.
---

# Add a book with its cover

The guardian names a book. You find it on Aladin (알라딘) in the ego lite browser, take the front cover, ISBN, page count and publisher from the product page, save the cover into the site, and write `_books/<slug>.md`. The original cover image goes to Google Drive and off this Mac.

## Steps

1. **Load the browser.** Load the `ego-browser` skill and run `ego-browser skill` once per session. Use one TaskSpace for the whole request and `finish({ keep: [] })` at the end.
2. **Search Aladin.** Open `https://www.aladin.co.kr/search/wsearchresult.aspx?SearchTarget=Book&SearchWord=<encodeURIComponent(title)>` with `waitUntil: "domcontentloaded"`. Read the top results with the script below.
3. **Pick the edition.** Choose the result whose title and author match. Prefer the main edition of the book, not a series spin-off, an audiobook, an e-book (`[eBook]`) or a set (`세트`). If two editions are equally plausible, or nothing matches, show the guardian the candidates and ask.
4. **Read the product page.** Open the result's `href` and read `og:image` (`.../cover500/...jpg`), the ISBN, the page count and the author with the script below. If `og:image` is missing, use the largest `img` whose src contains `/cover`.
5. **Download the cover** with `page.fetch(coverUrl, { saveAs: "/Volumes/ORICO/readcheck/media/inbox/<slug>-cover.jpg" })`. Look at it with the Read tool and confirm that it is the front cover, not a spine, a back cover or a placeholder.
6. **Make the site cover.** Run `python3 scripts/make_cover.py media/inbox/<slug>-cover.jpg <slug>`. It writes `assets/covers/<slug>.webp` and moves the original to `media/covers/`.
7. **Write the book file.** Copy `_templates/book.md` to `_books/<slug>.md` and set the fields below. Then run `ruby scripts/check_books.rb` until it passes.
8. **Move the original to Drive.** Run `python3 scripts/drive_archive.py sweep`, then the same with `--apply`. It uploads to `시몬 책장/표지 원본/`, checks the md5 and deletes the local file.
9. **Show the guardian** the cover (Read the webp), the front matter and the shelf it will go on. Commit only `_books/<slug>.md` and `assets/covers/<slug>.webp` after they agree, and push to `main` only when they ask.

## Fields

- `slug`: short romanized title in lowercase with `-`, such as `gureumppang` for 구름빵. It must not clash with a file in `_books/`.
- `title`: the title without the series name after `ㅣ`.
- `author`: the writer as Aladin lists them before `(지은이)`. Leave out illustrators and translators unless the guardian wants them.
- `status`: ask if the guardian did not say. `reading` gets `started` = today; `finished` needs `finished`.
- `cover: "/assets/covers/<slug>.webp"`, `isbn: "<13 digits>"` (quoted), `pages` from `쪽`.
- `genre`: `그림책` for picture books, `동화` for children's fiction, `지식 책` for non-fiction, when it is clear.
- `summary`: one or two sentences in your own words, in the site's warm Korean ending in 요. Never copy the publisher's description.
- `published: true` unless the guardian says otherwise. Leave the body empty for Simon's notes.

## Browser scripts

Search results:

```js
const items = await page.evaluate(() => [...document.querySelectorAll('.ss_book_box')].slice(0, 8).map(b => ({
  title: b.querySelector('a.bo3')?.textContent.trim(),
  href: b.querySelector('a.bo3')?.href,
  meta: b.querySelector('.ss_book_list')?.innerText.split('\n').slice(0, 3).join(' / ')
})));
```

Product page:

```js
const info = await page.evaluate(() => {
  const text = document.body.innerText;
  return {
    cover: document.querySelector('meta[property="og:image"]')?.content,
    title: document.querySelector('meta[property="og:title"]')?.content,
    author: document.querySelector('meta[name="author"]')?.content,
    isbn: (text.match(/ISBN\s*:?\s*(97[89]\d{10})/) || [])[1],
    pages: (text.match(/(\d+)쪽/) || [])[1],
  };
});
```

## If Aladin fails

If the search page does not load or the book is not there, try Kyobo (`https://search.kyobobook.co.kr/search?keyword=...`) and read the product page's `og:image` the same way. If a page asks for a login or a CAPTCHA, hand off to the user instead of working around it. If no cover can be found, write the book without `cover`; the site draws a coloured cover.

## Existing books without a cover

For "표지 찾아 줘" on a book already in `_books/`, run steps 2 to 6 and 8 with its existing slug, then add or replace its `cover` line.
