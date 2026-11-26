#!/bin/sh
# Builds Sophia's reading pages from this repository (same code as Simon's, her data in _kids/sophia)
# and copies them into the sophia-blog folder, which serves sophia.itdo.work.
#
#   scripts/build_sophia.sh [sophia-blog folder]     (default /Volumes/ORICO/sophia-blog)
#
# Copies /reading/ and the shared assets; leaves her blog's own files (index, diary, schedule, assets/blog) alone.
# Commit and push the sophia-blog folder yourself afterwards.
set -eu
ROOT=$(cd "$(dirname "$0")/.." && pwd)
DEST=${1:-/Volumes/ORICO/sophia-blog}
OUT=$(mktemp -d)
trap 'rm -rf "$OUT"' EXIT
PATH=/opt/homebrew/opt/ruby/bin:/opt/homebrew/lib/ruby/gems/4.0.0/bin:$PATH
cd "$ROOT"
jekyll build -q --config _config.yml,_kids/sophia/_config.yml -d "$OUT"
test -f "$OUT/reading/index.html" || { echo "build has no reading page" >&2; exit 1; }
mkdir -p "$DEST/reading" "$DEST/assets/covers"
rsync -a --delete "$OUT/reading/" "$DEST/reading/"
# Everything in assets except the blog's own folder and other children's covers.
rsync -a --delete --exclude /blog --exclude /covers "$OUT/assets/" "$DEST/assets/"
rsync -a --delete "$OUT/assets/covers/sophia/" "$DEST/assets/covers/sophia/"
echo "Sophia's reading pages copied to $DEST (not committed)"
