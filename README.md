# 시몬의 책 읽기

**책장:** https://simon.itdo.work/

GitHub Pages가 Markdown 파일을 정적 페이지로 만들고 직접 제공합니다.
독자에게 서버, 데이터베이스, 로그인, AI 호출은 필요하지 않습니다.
`main`에 변경을 저장하면 GitHub의 Pages 빌드가 실행됩니다. 예약 작업은 없습니다.

책 한 권이 `_books/`의 파일 하나입니다. 파일의 front matter가 책장 카드와 책 페이지를 만들고,
`quiz` 항목이 독서 확인 퀴즈가 됩니다.

## 새 책 추가하기

책장 위쪽의 **+ 책 추가**(`/add/`)를 누르면 네 단계로 책을 등록합니다.

1. **책 고르기**: 제목이나 지은이로 검색하거나 아래 **추천 책**에서 고릅니다. 한글 검색어는 도서관 정보나루 → Google Books → Open Library 순서로,
   영어 검색어는 Google Books → Open Library 순서로 찾습니다. 도서관 정보나루는 `_config.yml`의 `data4library_key`가 있을 때만 씁니다.
   표지, 쪽수, ISBN이 자동으로 채워집니다. 없는 책은 **직접 입력하기**를 누릅니다.
2. **정보 확인**: 상태(읽는 중, 읽고 싶은 책, 다 읽은 책, 잠시 멈춤), 날짜, 별점, 한두 문장 소개를 확인합니다.
   책 주소는 제목에서 자동으로 만들어지며 **주소와 공개 설정**에서 바꿀 수 있습니다.
3. **퀴즈 사진**: 읽은 쪽을 사진으로 찍어 퀴즈를 만드는 방법을 안내합니다. 건너뛰어도 됩니다.
4. **저장**: **GitHub에 저장하기**를 누르면 책 파일이 채워진 GitHub 새 파일 화면이 열립니다.
   **Commit changes**를 누르면 1분쯤 뒤 책장에 나옵니다.

작성 중인 내용은 그 기기의 브라우저에 임시로 남습니다. 저장한 책이 책장에 나오면 다음 방문 때 지워집니다.
손으로 쓰고 싶다면 예전처럼 [`_templates/book.md`](./_templates/book.md)를 복사해 `_books/my-book.md`로 만들어도 됩니다.

### 표지까지 자동으로 넣기 (Claude Code)

Claude Code에 `"책 제목" 책 추가해`라고 보내면 `add-book` 스킬이 ego lite 브라우저로 알라딘에서 책을 찾아
앞표지, ISBN, 쪽수를 가져오고 `_books/<책 주소>.md`를 만듭니다. 판이 여러 개면 어느 것인지 물어봅니다.
표지는 `scripts/make_cover.py`로 400px WebP(`assets/covers/<책 주소>.webp`)로 줄여 사이트에 넣고,
원본은 `drive_archive.py sweep --apply`로 Drive의 `시몬 책장/표지 원본/`에 올린 뒤 Mac에서 지웁니다.
이미 있는 책의 표지만 바꾸려면 `"책 제목" 표지 찾아 줘`라고 보냅니다.
책 파일의 `cover`에는 `https://` 주소나 `/assets/covers/<책 주소>.webp`를 쓸 수 있습니다.

### 추천 책

추천 목록은 [`_data/recommendations.yml`](./_data/recommendations.yml)에 있습니다. 제목, 지은이, 장르,
`level`(그림책, 저학년, 중학년), 추천 이유를 적습니다. 이미 책장에 있는 책은 추천에서 빠집니다.
별점 4점 이상인 책이 있으면 그 지은이의 다른 책도 검색해서 함께 보여 줍니다.

### 책 검색 키 (선택)

Google Books는 키 없이 쓰면 하루 사용량이 금방 찰 수 있습니다. 그럴 때는 Open Library에서 찾습니다.
더 안정적으로 쓰려면 Google Cloud에서 Books API 키를 만들고 **HTTP 리퍼러를 `simon.itdo.work/*`로 제한**한 뒤
`_config.yml`의 `google_books_key`에 넣습니다. 이 값은 공개되므로 제한하지 않은 키는 넣지 않습니다.

`status`는 `_data/shelves.yml`의 `key` 중 하나입니다.

| status | 책장 | 카드에 보이는 날짜 |
| --- | --- | --- |
| `reading` | 읽는 중 | `started` |
| `want` | 읽고 싶은 책 | 없음 |
| `finished` | 다 읽은 책 | `finished` |
| `paused` | 잠시 멈춤 | `started` |

책장 이름, 순서, 색은 `_data/shelves.yml`에서 고칩니다. 템플릿은 바꾸지 않아도 됩니다.

`cover`는 `https://`로 시작하는 표지 그림 주소나 `/assets/covers/<책 주소>.webp`이고, 없으면 색 표지를 그립니다. `isbn`은 따옴표로 감싼 숫자입니다.
`structure`는 구조 그리기의 첫 모양이며 `mountain`(이야기 산), `three`(처음·가운데·끝), `map`(생각 지도) 중 하나입니다.

올해 목표(`reading_goal`)에는 `status: finished`이면서 `finished` 날짜가 올해인 책만 셉니다.
다 읽은 책에는 `finished`를 꼭 적습니다.

이 저장소는 공개입니다. 공개해도 되는 글과 사진만 올리세요. `published: false`는
책장에서만 숨기며 저장소나 Git 기록을 비공개로 만들지 않습니다. 개인 초안은
로컬 파일에 보관하고, 확인한 책만 업로드합니다.

## 이번 주 책 고르기 (첫 화면)

첫 화면은 이번 주에 읽을 책 두 권을 실제 크기 비율의 3D 책으로 보여 줍니다. 책을 손가락으로 돌리거나 톡 눌러 뒤표지를 봅니다.
책마다 그 책에서 태어난 캐릭터(책콩)가 함께 있습니다. 한 권을 고르면 네 단계가 나옵니다.

1. **종이에 독후감 쓰기**
2. **독후감 사진 찍기**: iPad 카메라로 찍습니다. 사진은 그 iPad의 브라우저(IndexedDB)에만 저장되고 저장소에는 올라가지 않습니다.
3. **AI와 이야기하기**: 책 정보와 대화 순서가 들어 있는 프롬프트를 복사하거나, **사진이랑 같이 보내기**로 Claude·ChatGPT 앱에 사진과 함께 보냅니다.
4. **책장에 꽂기**: 사진을 넣어야 누를 수 있습니다. 그전까지 **나만의 책장**은 잠겨 있습니다.

책장에 꽂으면 그 책의 **포켓몬 카드 부스터 팩**이 나옵니다. 팩 윗부분을 손가락으로 쭉 밀거나 세 번 톡톡 누르면 뜯어지고,
카드 10장이 실제 카드 뒷면으로 나옵니다. 한 장씩 눌러 뒤집으면 커먼·언커먼·리버스 홀로가 나오고, 9번째 장은 실제 팩처럼
약 36% 확률로 더블 레어부터 스페셜 일러스트 레어까지의 좋은 카드로 바뀝니다. 10번째 장은 그 책에 정해진 카드로 확정입니다.
9장은 그 카드가 속한 실제 세트의 카드 목록(`_data/card_pools/<세트>.json`, `ruby scripts/card_pool.rb <세트>`로 만듦)에서 뽑고,
뽑은 결과는 iPad에 저장되어 새로고침해도 바뀌지 않습니다. 모은 카드는 책장 아래 **카드 바인더**에 쌓입니다.
카드 뒷면은 pokemon.com의 공식 이미지를 바로 불러옵니다. 반짝이·홀로 결·팩 비닐 주름 질감(`assets/fx`)은 Blender로 이 사이트를 위해 렌더링한 것입니다.
책을 고를 때도 두 책이 서로 다른 시리즈의 팩과 그 팩에서 나올 카드를 보여 줍니다.
카드 그림은 Pokémon TCG API(pokemontcg.io), 팩 사진은 TCGplayer에서 바로 불러오고 저장소에는 복사하지 않습니다.
카드 번호(`card.number`)는 `_data/roadmap.yml` 전체에서 몇 번째 책인지이고, 등급(`rarity`)은 Must가 SR, Better가 R입니다.
카드를 손가락으로 기울이거나 iPad를 기울이면 홀로그램과 빛 반사가 따라 움직입니다. iPad를 처음 기울일 때는 동작 권한을 한 번 묻습니다.
받은 카드는 나만의 책장과 책 페이지에 책과 짝지어 나옵니다. 책마다 어울리는 카드와 팩은 `weekly-books` 스킬이 고릅니다.
카드 정보(`card`)는 **GitHub에 기록하기**로 저장하는 책 파일에 함께 들어갑니다.

책장에 꽂으면 보호자용 **GitHub에 기록하기** 링크가 나옵니다. 이것으로 `_books/<책 주소>.md`를 저장해야
`scripts/next_pair.rb`가 책을 다 읽었다고 알고, 다음 토요일에 보여 줄 두 권을 고릅니다.
다음 두 권은 Claude Code의 `weekly-books` 스킬이 준비합니다. 알라딘(ego lite)에서 표지·쪽수·크기를 가져오고,
Google Flow로 캐릭터 그림을 만들어 `_data/weekly.yml`에 씁니다. 고르지 않은 책은 다음 주에 한 번 더 나옵니다.
책 순서는 `_data/roadmap.yml`(`docs/reading-roadmap.md`와 같은 목록)을 따르고, 학년은 해마다 3월에 하나씩 올라갑니다.

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

정답은 페이지 소스에 그대로 들어 있습니다. 독서 확인은 시험이 아니라 스스로 점검하는 도구입니다.

사진으로 찍은 책 쪽에서 퀴즈를 만들고 싶다면 Claude Code의 `.claude/skills/make-quiz/SKILL.md` 스킬을 쓰세요.
쪽 사진을 `media/inbox/`에 넣고(AirDrop) `"책 제목" 퀴즈 만들어`라고 보내면 질문을 `quiz`에 적고
`ruby scripts/check_books.rb`로 확인한 뒤, 보호자가 확인하면 사진을 Drive로 옮기고 Mac에서 지웁니다.
퀴즈가 없는 책 페이지에도 이 안내와 복사할 문장이 나옵니다.

### 문제지로 인쇄하기

퀴즈가 있는 책 페이지에서 **퀴즈 인쇄하기**를 누르거나 브라우저의 인쇄(`Ctrl+P`, `⌘P`)를 쓰면
제목, 이름·날짜 칸, 번호가 붙은 문제와 보기가 A4 종이에 나옵니다.
그다음 쪽은 종이에 직접 그리는 **책의 구조 그리기**(이야기 산)이고, 정답과 설명은 마지막 쪽에 따로 나옵니다.
아이에게 건네기 전에 마지막 쪽은 빼고 인쇄합니다.
문제지는 자바스크립트 없이도 인쇄됩니다. 문제지에 필요한 값은 모두 책 파일의 `quiz`에서 옵니다.

### 점수는 어디에 저장되나요

점수는 이 기기, 이 브라우저의 `localStorage`에만 저장됩니다. 서버로 보내지 않습니다.
책마다 가장 좋은 결과와 최근 시도 20번이 남고, 책 페이지에는 `지난 기록`으로 최근 5번이 보입니다.
책장에는 통과한 책의 수가 `독서 확인 통과 N권`으로 나옵니다.
브라우저의 사이트 데이터를 지우거나 다른 기기, 다른 브라우저로 바꾸면 기록은 사라지거나 따라가지 않습니다.

## 파일 확인하기

저장하기 전에 책 파일을 확인합니다. Ruby만 있으면 되고, 따로 설치할 것이 없습니다.

```sh
ruby scripts/check_books.rb
```

모든 `_books/*.md`의 항목을 확인하고 문제가 있으면 파일 이름과 함께 알려 준 뒤 실패로 끝납니다.
파일 몇 개만 확인하려면 경로를 뒤에 적습니다.

## 책의 구조 그리기

`읽고 싶은 책`이 아닌 책 페이지에는 **책의 구조를 그려 봐요**가 있습니다. 퀴즈 결과 화면의
**다음: 책의 구조 그리기**도 이곳으로 옵니다. 손가락, 펜, 마우스로 그리고, 모양은 세 가지입니다.

- **이야기 산**: 처음 → 사건 → 절정 → 해결 → 끝
- **처음 · 가운데 · 끝**: 세 칸
- **생각 지도**: 책 제목을 가운데에 두고 인물, 장소, 사건, 느낌, 배운 점, 궁금한 점

색, 굵기, 지우개, 되돌리기(`⌘Z`/`Ctrl+Z`)를 쓸 수 있습니다. 그림은 그 기기의 브라우저에 저절로 저장됩니다.
**그림 저장하기**를 누르면 `<책 주소>-structure-<날짜>.png` 파일이 다운로드 폴더에 생깁니다.

## 이미지와 Google Drive

원본 이미지는 저장소에 넣지 않고 Google Drive의 `시몬 책장/` 폴더에 모읍니다. Mac에는 남기지 않습니다.

| 이미지 | Mac에서 두는 곳 | Drive 폴더 |
| --- | --- | --- |
| 퀴즈용 쪽 사진 | `media/inbox/` → 퀴즈를 만든 뒤 `media/pages/<책 주소>/` | `시몬 책장/쪽 사진/<책 주소>/` |
| 구조 그림 | `~/Downloads/<책 주소>-structure-*.png` | `시몬 책장/구조 그림/<책 주소>/` |
| 사이트 일러스트 원본 | `media/flow/` | `시몬 책장/일러스트 원본/` |
| 책 표지 원본 | `media/covers/` | `시몬 책장/표지 원본/` |

`media/`는 `.gitignore`에 들어 있어 커밋되지 않습니다. 정리할 때는 다음을 실행합니다.

```sh
python3 scripts/drive_archive.py sweep          # 무엇을 옮길지 보기만 해요
python3 scripts/drive_archive.py sweep --apply  # Drive에 올리고, md5를 확인한 뒤 Mac에서 지워요
python3 scripts/drive_archive.py verify         # Drive에 올린 파일이 그대로인지 확인해요
```

Drive 사본의 md5가 Mac의 파일과 같을 때만 지우고, 다르면 `KEPT`로 알려 주고 남겨 둡니다.
휴지통으로 옮기고 싶다면 `--trash`를 붙입니다(공간은 휴지통을 비워야 돌아옵니다).
다른 곳의 파일은 `push FILE... --to pages|drawings|flow --book <책 주소> --apply`로 올립니다.
`gws` CLI가 `drive.file` 권한으로 로그인되어 있어야 합니다(`gws auth status`). Drive 파일 목록은 `media/.drive-index.json`에
남으니 지우지 않습니다. 지우면 다음 정리 때 같은 파일이 Drive에 한 번 더 올라갑니다.

사이트 일러스트(`assets/img/*.webp`)는 Google Flow(Nano Banana 2.1)로 만든 그림을 웹용 WebP로 줄인 것입니다.
그림을 바꾸려면 Flow 프로젝트 **시몬 책장 일러스트**에서 새로 만들어 `media/flow/`에 받은 뒤
`cwebp -q 82 -resize <폭> 0 원본.jpg -o assets/img/<이름>.webp`로 줄이고 `sweep --apply`로 원본을 Drive에 옮깁니다.

### 독서 노트에 사진 넣기

보호자가 확인한 사진만 `assets/books/`에 작게 줄여 올리고 독서 노트에서 다음처럼 연결합니다.

```markdown
![내가 그린 장면]({{ '/assets/books/my-drawing.jpg' | relative_url }})
```

사진 속 이름, 학교 등 공개하지 않을 정보는 업로드 전에 제거합니다.

## 수정하거나 내리기

- 수정: `_books/`의 파일을 고쳐 `main`에 저장합니다.
- 책장에서 내리기: `published: false`로 바꾸거나 해당 파일을 삭제하고 저장합니다.
- 사용하지 않는 사진도 삭제합니다. Pages 배포가 끝난 뒤 실제 주소를 확인합니다.
- 공개 저장소의 Git 기록이나 이미 내려받은 사본까지 삭제되는 것은 아닙니다.

## 운영

- Pages source: **Deploy from a branch → main → / (root)**.
- Jekyll이 `_config.yml`, `_layouts/`, `_includes/`, `_data/`, `_books/`를 빌드합니다.
- `_templates/`, `scripts/`, `media/`와 README는 사이트에 배포하지 않습니다.
- 첫 배포의 책장은 비어 있습니다. `_books/example-book.md`는 `published: false`인 예시이며 시몬의 책으로 표시하지 않습니다.
- 이 사이트는 `noindex`로 검색 엔진에 노출하지 않습니다.
- 원본 사진, 개인 학습 기록, 인증 정보, 서버 코드는 이 저장소에 포함하지 않습니다.

### 주소

- 이 사이트는 `CNAME` 파일로 `simon.itdo.work` 주소를 씁니다. 예전 수학 블로그 저장소의 이름을 바꿔 만든 저장소라서 같은 주소를 이어받았습니다.
- 주소를 바꾸려면 `CNAME`과 `_config.yml`의 `url`을 함께 고칩니다. `CNAME`을 지우고 `github.io` 주소를 쓰려면 `baseurl`을 `/simon-reading-books`로 바꿉니다.
- 저장소 이름을 바꾸면 `_config.yml`의 `repository`와 `write_url`도 고칩니다.

참고: [GitHub의 Jekyll 글 작성 안내](https://docs.github.com/en/pages/setting-up-a-github-pages-site-with-jekyll/adding-content-to-your-github-pages-site-using-jekyll).

## 다음 책 예약 (책 추가 메뉴)

`/reading/add/`에서 다음에 읽을 책 두 권을 미리 골라 둬요. 목록은 `_data/roadmap.yml`(= `docs/reading-roadmap.md`)의 126권이고, 고른 두 권은 이 iPad에만 저장돼요(`localStorage`의 `readcheck:next:v1`).

- 지금 책을 읽는 동안에는 두 권을 언제든 바꿀 수 있어요. 다 읽으면 바꿀 수 없고, 팩을 뜯은 뒤 읽기 화면에서 둘 중 하나를 골라요. 고르지 않은 책은 자리에 남아요.
- 책마다 진짜 부스터 팩과 그 팩의 스페셜 일러스트 레어 카드가 두 가지씩 짝지어져 있어요(`_data/book_packs.yml`). 두 권이 같은 팩이면 나중에 고른 책이 둘째 팩을 써서, 두 권의 팩은 언제나 달라요.
- 팩 목록은 `_data/packs.yml`(TCGplayer 팩 사진), 카드 목록은 `_data/card_pools/`예요. 팩을 더하면 `ruby scripts/card_pool.rb <set>`, `ruby scripts/book_packs.rb` 순서로 돌려요.
- 표지·ISBN·쪽수·크기는 `ruby scripts/roadmap_books.rb`가 알라딘에서 찾아 `assets/covers/`와 `_data/book_meta.yml`에 써요. 로드맵에 책을 더하면 다시 돌려요.
- 예약한 책이 없으면 예전처럼 `_data/weekly.yml`의 두 권이 나와요.
- 그림(`assets/img/next-books.webp`, `next-slot.webp`)은 Google Flow로 만들었어요.

## 소피아의 책 읽기 (sophia.itdo.work/reading/)

소피아의 책 읽기 화면은 시몬과 **같은 코드**(이 저장소의 페이지와 assets)를 쓰고, **이번 책**과 **책 추가** 목록만 따로 가져요.

- 설정: `_kids/sophia/_config.yml`이 `_config.yml` 위에 덮여요. 이름(`kid`), 보라색 띠, 1학년용 그림 독후감 문구, 데이터 폴더를 바꿔요.
- 목록: `docs/reading-roadmap-sophia.md` = `_kids/sophia/_data/roadmap.yml`. 초1~초4, 학년마다 Must 10권 + Better 20권, 모두 120권이에요.
- 카드: 포켓몬 대신 **진짜 디즈니 로카나 카드**(디즈니 프린세스)예요. `ruby scripts/lorcana_cards.rb`가 세트별 팩(`packs.yml`), 팩 뜯기용 카드 목록(`card_pools/`), 책마다 카드 두 장(`book_packs.yml`)을 써요. 카드 뒷면과 토끼 그림은 Google Flow로 그렸어요(`assets/img/sophia/`).
- 표지: `KID=sophia ruby scripts/roadmap_books.rb` → `assets/covers/sophia/`, `_kids/sophia/_data/book_meta.yml`.
- 다 읽은 책: `_kids/sophia/_books/` (보호자의 GitHub 기록 링크가 여기에 파일을 만들어요).
- 배포: `scripts/build_sophia.sh`가 소피아용으로 빌드해 `/Volumes/ORICO/sophia-blog`의 `reading/`과 `assets/`에 복사해요. 그 폴더를 커밋하고 푸시하면 sophia.itdo.work에 올라가요. 공용 코드를 고친 뒤에도 이 스크립트를 다시 돌려야 소피아 화면에 반영돼요.
- kids-blog의 소피아 사이트는 시몬처럼 `overlay` 방식이라, 블로그 자동 게시가 `reading/`을 지우지 않아요.
