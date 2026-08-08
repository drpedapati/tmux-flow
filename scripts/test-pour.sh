#!/bin/bash
# Verify tmux-flow installs from a bottle (pours) rather than compiling.
set -uo pipefail

export HOMEBREW_NO_AUTO_UPDATE=1

TAP="$(brew --repository)/Library/Taps/drpedapati/homebrew-tools"
git -C "$TAP" fetch -q origin
git -C "$TAP" checkout -q -B bottletest origin/feat/bottles
echo "== tap: $(git -C "$TAP" log --oneline -1)"
echo "== bottle block present: $(grep -c 'bottle do' "$TAP/Formula/tmux-flow.rb")"

brew uninstall --force tmux-flow >/dev/null 2>&1 || true

LOG=$(mktemp)
START=$(date +%s)
brew install drpedapati/tools/tmux-flow > "$LOG" 2>&1
RC=$?
END=$(date +%s)

echo "== exit=$RC  elapsed=$((END-START))s"
if grep -qi 'pouring' "$LOG"; then
  echo "== POURED FROM BOTTLE:"
  grep -i 'pouring' "$LOG" | sed 's/^/     /'
else
  echo "== DID NOT POUR (compiled from source or failed)"
  grep -iE 'installing|building|error|warning: .*bottle|not found' "$LOG" | head -10 | sed 's/^/     /'
fi

echo "== installed: $(brew list --versions tmux-flow 2>/dev/null || echo NONE)"
echo "== tap after install: $(git -C "$TAP" log --oneline -1)"

# Restore tap to main so nothing is left on a branch.
git -C "$TAP" checkout -q main 2>/dev/null
git -C "$TAP" branch -q -D bottletest 2>/dev/null
rm -f "$LOG"
