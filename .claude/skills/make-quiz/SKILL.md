---
name: make-quiz
description: Turn photos of book pages into a readcheck quiz for Simon's reading shelf. Use when the user shares page photos or pasted book text and asks for a quiz, "퀴즈 만들어", "독서 확인 만들어", or names a book in _books/ that needs questions.
---

# Make a readcheck quiz

A guardian gives you photos of the pages Simon just read. You write multiple-choice questions about that exact text into the book's file in `_books/`, so the quiz appears on the site. Simon is a child reading in Korean. The quiz checks that he read and understood the pages. It is not an exam.

## Steps

1. **Read every photo** with the Read tool. If a page is too blurry or cropped to read, say which one and ask for a retake. Never write a question about text you could not read.
2. **Find the book file.** Match the title to a file in `_books/`. If none exists, copy `_templates/book.md` to `_books/<short-english-slug>.md`. The validator requires `title`, `author`, `status` and `summary`. Ask for the author and the status if you were not told. Write a one-sentence `summary` from what you read. For a finished book, set `finished` to the day the guardian says, or today when they say Simon read it today. Leave out `rating`, `genre` and `pages` unless the guardian gives them. Leave the body under the front matter empty, because that space is for Simon's own notes.
3. **Write the questions** following the rules below.
4. **Put them in the file's `quiz:` list.** If the book already has a quiz, ask whether to replace it or add to it. Keep one book at 10 questions or fewer, and drop the oldest when adding would pass that.
5. **Validate.** Run `ruby scripts/check_books.rb`. Fix every error it prints and run it again until it passes.
6. **Show the guardian the questions and answers** in your reply, and wait for their OK before publishing. They know the book and Simon. You only know the photos.
7. **Publish when they agree.** Set `published: true` if they want the book on the shelf, commit only the book file by naming its path in `git add`, and push to `main`. The site rebuilds itself in about a minute.

## Question rules

- Write 5 questions for up to about five pages, and add roughly one per extra page up to 10.
- Ask only about the pages in the photos. If the guardian says Simon read more than the photos show, write the quiz for what you have and tell them which part it covers.
- Every question must be answerable from the photographed pages alone. A reader who skipped the pages should not be able to guess it from general knowledge.
- Mix the kinds. Most ask what happened or who did what. One or two ask what a word from the text means in that sentence. One asks why someone did something or how they felt, where the text supports a clear answer.
- Use 3 choices for picture books and 4 for books with chapters. Exactly one is right. Wrong choices are plausible and about the same length as the right one.
- Spread the right answer across positions. Do not put it first every time.
- Write in the warm, plain Korean the site uses, ending sentences with 요. Keep each question to one sentence.
- Add a `why` of one short sentence that says what the text shows. Paraphrase it.
- No trick questions, no "모두 맞다" or "모두 아니다" choices, and no questions about page numbers.

## Format

`answer` counts from 1.

```yaml
quiz:
  - q: "주인공이 숲에서 처음 만난 동물은 무엇이었나요?"
    choices: ["여우", "부엉이", "토끼"]
    answer: 2
    why: "숲에 들어서자마자 나무 위의 부엉이가 말을 걸었어요."
```

Quote YAML strings with double quotes. A double quote inside a string is written `\"`.

## What stays out of the repository

The repository is public.

- **The photos.** Never copy them into the repo or commit them.
- **Long passages from the book.** Questions, choices and `why` paraphrase. A `quote` is one sentence at most.
- **Personal details** visible in a photo, such as a name label, a school, or a library card.
