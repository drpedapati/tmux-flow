#!/bin/bash
# Build a tmux-flow Homebrew bottle for the current platform.
# Usage: build-bottle.sh <version>
set -euo pipefail

V="${1:?usage: build-bottle.sh <version>}"
ROOT_URL="https://github.com/drpedapati/tmux-flow/releases/download/v${V}"
OUT="$HOME/bottling"

# NO_AUTO_UPDATE stops brew resetting the tap checkout mid-install.
# Do NOT set HOMEBREW_NO_INSTALL_FROM_API: it disables the formula API, and
# core deps like autoconf then fail to resolve.
export HOMEBREW_NO_AUTO_UPDATE=1

echo "== platform: $(uname -s) $(uname -m)"

TAP="$(brew --repository)/Library/Taps/drpedapati/homebrew-tools"
git -C "$TAP" checkout -q main
git -C "$TAP" pull -q --ff-only origin main
echo "== tap: $(git -C "$TAP" log --oneline -1)"

FORMULA_V=$(grep -oE 'archive/refs/tags/v[0-9.]+\.tar\.gz' "$TAP/Formula/tmux-flow.rb" | head -1)
echo "== formula url tag: $FORMULA_V (want v${V})"
case "$FORMULA_V" in
  *"v${V}.tar.gz") : ;;
  *) echo "!! formula is not at v${V}; aborting"; exit 1 ;;
esac

rm -rf "$OUT"; mkdir -p "$OUT"; cd "$OUT"

echo "== uninstalling any existing tmux-flow"
brew uninstall --force tmux-flow >/dev/null 2>&1 || true

echo "== brew install --build-bottle (this compiles; takes a few minutes)"
if ! brew install --build-bottle drpedapati/tools/tmux-flow > "$OUT/install.log" 2>&1; then
  echo "!! install failed; tail:"
  tail -25 "$OUT/install.log"
  exit 1
fi
echo "== installed: $(brew list --versions tmux-flow)"

echo "== brew bottle"
brew bottle --json --no-rebuild --root-url="$ROOT_URL" drpedapati/tools/tmux-flow \
  > "$OUT/bottle.out" 2>&1 || { echo "!! bottle failed:"; tail -25 "$OUT/bottle.out"; exit 1; }
cat "$OUT/bottle.out"

echo "== artifacts in $OUT"
ls -1 "$OUT"
