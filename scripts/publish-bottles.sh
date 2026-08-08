#!/bin/bash
# Build, upload and register Homebrew bottles for a tmux-flow release.
#
#   scripts/publish-bottles.sh <version>
#
# Runs scripts/build-bottle.sh on each build host, uploads the results to the
# matching GitHub release, then writes the bottle block into the tap formula
# and pushes it.
#
# Build hosts are macOS and Linux; both must be reachable and have the tap.
set -euo pipefail

V="${1:?usage: publish-bottles.sh <version>}"
REPO="drpedapati/tmux-flow"
TAP="${TAP:-/tmp/homebrew-tools}"
FORMULA="$TAP/Formula/tmux-flow.rb"
ROOT_URL="https://github.com/$REPO/releases/download/v${V}"

# host:label pairs. The local machine is used for its own platform.
MAC_HOST="${MAC_HOST:-macbookm5}"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

echo "== checking release v$V exists"
gh release view "v$V" --repo "$REPO" >/dev/null

echo "== building macOS bottle on $MAC_HOST"
scp -q "$(dirname "$0")/build-bottle.sh" "$MAC_HOST:/tmp/build-bottle.sh"
ssh -o BatchMode=yes "$MAC_HOST" "bash /tmp/build-bottle.sh $V" >"$WORK/mac.log" 2>&1 \
  || { echo "!! macOS bottle failed:"; tail -20 "$WORK/mac.log"; exit 1; }
scp -q "$MAC_HOST:~/bottling/tmux-flow--${V}."*.bottle.tar.gz "$WORK/"
scp -q "$MAC_HOST:~/bottling/tmux-flow--${V}."*.bottle.json "$WORK/"
echo "   done"

echo "== building Linux bottle locally"
bash "$(dirname "$0")/build-bottle.sh" "$V" >"$WORK/linux.log" 2>&1 \
  || { echo "!! Linux bottle failed:"; tail -20 "$WORK/linux.log"; exit 1; }
cp ~/bottling/tmux-flow--"${V}".*.bottle.tar.gz "$WORK/"
cp ~/bottling/tmux-flow--"${V}".*.bottle.json "$WORK/"
echo "   done"

echo "== uploading bottles to release v$V"
# brew bottle writes a double-dash file; Homebrew requests a single-dash name
# from root_url. Upload under the name in the JSON's "filename" field.
cd "$WORK"
UPLOADS=()
for f in tmux-flow--"${V}".*.bottle.tar.gz; do
  dest="${f/tmux-flow--/tmux-flow-}"
  cp "$f" "$dest"
  UPLOADS+=("$dest")
  echo "   $dest"
done
gh release upload "v$V" --repo "$REPO" "${UPLOADS[@]}" --clobber

echo "== building bottle block"
BLOCK="$WORK/block.txt"
{
  echo "  # Prebuilt binaries, so installing does not compile tmux from source."
  echo "  # Rebuild with scripts/publish-bottles.sh after tagging a new version."
  echo "  bottle do"
  echo "    root_url \"$ROOT_URL\""
  python3 - "$V" <<'PY'
import glob, json, sys
rows = []
for path in sorted(glob.glob("*.bottle.json")):
    for _, v in json.load(open(path)).items():
        for tag, info in v["bottle"]["tags"].items():
            rows.append((tag, info["sha256"]))
width = max(len(t) for t, _ in rows) + 1
for tag, sha in sorted(rows):
    print(f'    sha256 cellar: :any, {(tag + ":").ljust(width)} "{sha}"')
PY
  echo "  end"
} > "$BLOCK"
cat "$BLOCK" | sed 's/^/   /'

echo "== updating formula"
cd "$TAP"
git checkout -q main && git pull -q --ff-only origin main
# Drop any existing block, then insert the new one after the license line.
awk '/^  bottle do$/{s=1} s&&/^  end$/{s=0;next} !s' "$FORMULA" >"$WORK/f1"
awk -v blockfile="$BLOCK" '
  { print }
  /^  license / && !done {
    print ""
    while ((getline line < blockfile) > 0) print line
    done = 1
  }
' "$WORK/f1" >"$FORMULA"
ruby -c "$FORMULA" >/dev/null

git add Formula/tmux-flow.rb
git commit -q -m "tmux-flow: bottles for v$V"
git push -q origin main
echo "== pushed: $(git log --oneline -1)"
echo
echo "Verify with scripts/test-pour.sh on each platform."
