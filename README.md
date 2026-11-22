# 시몬의 책 읽기

**책장:** https://estherrunstrict.github.io/simon-reading-books/

GitHub Pages가 Markdown 파일을 정적 페이지로 만들고 직접 제공합니다.
독자에게 서버, 데이터베이스, 로그인, AI 호출은 필요하지 않습니다.
`main`에 변경을 저장하면 GitHub의 Pages 빌드가 실행됩니다. 예약 작업은 없습니다.

책 한 권이 `_books/`의 파일 하나입니다. 파일의 front matter가 책장 카드와 책 페이지를 만들고,
`quiz` 항목이 독서 확인 퀴즈가 됩니다.

## 새 책 추가하기

1. [`_templates/book.md`](./_templates/book.md)의 내용을 복사합니다.
2. **Add file → Create new file**을 눌러 `_books/my-book.md` 형식으로 파일을 만듭니다. `my-book`을 짧은 영문 이름으로 바꿉니다. 이 이름이 책 주소가 됩니다.
3. 제목, 지은이, 상태, 짧은 소개를 넣습니다. 나머지 항목은 없어도 됩니다.
4. 파일 아래쪽에 시몬이 직접 쓴 독서 노트를 Markdown으로 적습니다.
5. 보호자가 공개할 내용을 확인한 뒤 `published: true`로 바꾸고 **Commit changes**로 `main`에 저장합니다.
6. **Actions → pages build and deployment**가 초록색으로 끝나면 책장에서 확인합니다.

`status`는 `_data/shelves.yml`의 `key` 중 하나입니다.

| status | 책장 | 카드에 보이는 날짜 |
| --- | --- | --- |
| `reading` | 읽는 중 | `started` |
| `want` | 읽고 싶은 책 | 없음 |
| `finished` | 다 읽은 책 | `finished` |
| `paused` | 잠시 멈춤 | `started` |

책장 이름, 순서, 색은 `_data/shelves.yml`에서 고칩니다. 템플릿은 바꾸지 않아도 됩니다.

올해 목표(`reading_goal`)에는 `status: finished`이면서 `finished` 날짜가 올해인 책만 셉니다.
다 읽은 책에는 `finished`를 꼭 적습니다.

이 저장소는 공개입니다. 공개해도 되는 글과 사진만 올리세요. `published: false`는
책장에서만 숨기며 저장소나 Git 기록을 비공개로 만들지 않습니다. 개인 초안은
로컬 파일에 보관하고, 확인한 책만 업로드합니다.

## 독서 확인 퀴즈 만들기

책 파일의 `quiz`에 질문을 적으면 책 페이지에 독서 확인이 나타납니다. `quiz`가 없으면 나타나지 않습니다.

```yaml
quiz:
  - q: "도서관 고양이의 이름은 무엇이었나요?"
    choices: ["별이", "달이", "구름이"]
    answer: 1
    why: "고양이는 별빛 아래에서 태어나서 별이라는 이름을 얻었어요."
```

- `q`는 질문입니다.
- `choices`는 보기이며 2개 이상 적습니다. 숫자나 `yes`, `no`는 따옴표로 감쌉니다.
- `answer`는 정답 번호입니다. 첫 번째 보기가 1입니다.
- `why`는 답을 고른 뒤 보여줄 설명이며 없어도 됩니다.

`_config.yml`의 `readcheck.pass_percent`(기본 80) 이상 맞히면 통과입니다.
가장 좋은 결과는 그 기기의 브라우저에만 저장되고, 통과하면 책장 카드에 `독서 확인 통과 ✓`가 나타납니다.
다른 기기나 브라우저에는 기록이 따라가지 않습니다.

정답은 페이지 소스에 그대로 들어 있습니다. 독서 확인은 시험이 아니라 스스로 점검하는 도구입니다.

## 파일 확인하기

저장하기 전에 책 파일을 확인합니다. Ruby만 있으면 되고, 따로 설치할 것이 없습니다.

```sh
ruby scripts/check_books.rb
```

모든 `_books/*.md`의 항목을 확인하고 문제가 있으면 파일 이름과 함께 알려 준 뒤 실패로 끝납니다.
파일 몇 개만 확인하려면 경로를 뒤에 적습니다.

## 사진 넣기

보호자가 확인한 사진을 `assets/books/`에 업로드하고 독서 노트에서 다음처럼 연결합니다.

```markdown
![내가 그린 장면]({{ '/assets/books/my-drawing.jpg' | relative_url }})
```

사진 속 이름, 학교 등 공개하지 않을 정보는 업로드 전에 제거합니다.
다른 서버의 사진 주소를 연결할 필요가 없습니다.

## 수정하거나 내리기

- 수정: `_books/`의 파일을 고쳐 `main`에 저장합니다.
- 책장에서 내리기: `published: false`로 바꾸거나 해당 파일을 삭제하고 저장합니다.
- 사용하지 않는 사진도 삭제합니다. Pages 배포가 끝난 뒤 실제 주소를 확인합니다.
- 공개 저장소의 Git 기록이나 이미 내려받은 사본까지 삭제되는 것은 아닙니다.

## 운영

- Pages source: **Deploy from a branch → main → / (root)**.
- Jekyll이 `_config.yml`, `_layouts/`, `_includes/`, `_data/`, `_books/`를 빌드합니다.
- `_templates/`, `scripts/`와 README는 사이트에 배포하지 않습니다.
- 첫 배포의 책장은 비어 있습니다. `_books/example-book.md`는 `published: false`인 예시이며 시몬의 책으로 표시하지 않습니다.
- 이 사이트는 `noindex`로 검색 엔진에 노출하지 않습니다.
- 원본 사진, 개인 학습 기록, 인증 정보, 서버 코드는 이 저장소에 포함하지 않습니다.

### 처음 한 번만 하는 설정

주소는 저장소 이름에서 나옵니다. 이 사이트는 `simon-reading-books`라는 이름을 기준으로 `_config.yml`을 설정했습니다.

1. 저장소 이름을 `simon-reading-books`로 정합니다. 수학 블로그 저장소를 바꾸지 않고 새 저장소로 올리려면 새 저장소를 이 이름으로 만듭니다.
2. 다른 이름을 쓰면 `_config.yml`의 `baseurl`, `repository`, `write_url`을 그 이름에 맞게 고칩니다.
3. **Settings → Pages**에서 위의 Pages source를 선택합니다.

기존 수학 블로그는 `simon.itdo.work` 주소를 쓰고 있었습니다. 이 저장소는 `CNAME` 파일이 없으므로,
수학 블로그 저장소의 이름을 바꿔 이 사이트로 쓰면 수학 블로그가 그 주소에서 사라집니다.
수학 블로그를 계속 열어 두려면 별도 저장소로 남겨 둡니다.

참고: [GitHub의 Jekyll 글 작성 안내](https://docs.github.com/en/pages/setting-up-a-github-pages-site-with-jekyll/adding-content-to-your-github-pages-site-using-jekyll).
