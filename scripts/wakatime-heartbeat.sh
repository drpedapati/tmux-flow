#!/bin/sh
# Send a Wakapi heartbeat on pane focus.
# project  = git repo root name (or dir basename if not in a repo)
# branch   = current git branch
# editor   = pane_current_command (claude, codex, lazygit, zsh, ...)
# category = same as editor
# Deduplicates on path+command pair — 120s cooldown on same pair.

DIR="$1"
CMD="$2"
[ -z "$DIR" ] && exit 0

CFG=~/.wakatime.cfg
[ -f "$CFG" ] || exit 0

API_KEY=$(grep -E '^\s*api_key\s*=' "$CFG" | sed 's/.*=\s*//' | tr -d '[:space:]')
[ -z "$API_KEY" ] && exit 0

API_URL=$(grep -E '^\s*api_url\s*=' "$CFG" | sed 's/.*=\s*//' | tr -d '[:space:]')
[ -z "$API_URL" ] && API_URL="https://wakatime.com/api"

# Dedup on path+command — either changing means fire immediately
STATE=/tmp/tmux-wakapi-last
LAST_ENTITY=""
LAST_CMD=""
LAST_TIME=0
if [ -f "$STATE" ]; then
    LAST_ENTITY=$(cut -d'|' -f1 "$STATE")
    LAST_CMD=$(cut -d'|' -f2 "$STATE")
    LAST_TIME=$(cut -d'|' -f3 "$STATE")
fi

NOW=$(date +%s)
ELAPSED=$((NOW - LAST_TIME))

[ "$DIR" = "$LAST_ENTITY" ] && [ "$CMD" = "$LAST_CMD" ] && [ "$ELAPSED" -lt 120 ] && exit 0

printf '%s|%s|%s' "$DIR" "$CMD" "$NOW" > "$STATE"

# Use git root as project name so subdirectory panes still report the right repo
GIT_ROOT=$(git -C "$DIR" rev-parse --show-toplevel 2>/dev/null)
if [ -n "$GIT_ROOT" ]; then
    PROJECT=$(basename "$GIT_ROOT")
    BRANCH=$(git -C "$DIR" rev-parse --abbrev-ref HEAD 2>/dev/null)
else
    PROJECT=$(basename "$DIR")
    BRANCH=""
fi

MACHINE=$(hostname -s 2>/dev/null || hostname)

if [ -n "$BRANCH" ]; then
    BRANCH_JSON=",\"branch\":\"$BRANCH\""
else
    BRANCH_JSON=""
fi

curl -s -o /dev/null \
  -X POST \
  -H "Content-Type: application/json" \
  -H "User-Agent: wakatime/15.0.0 (darwin-arm64) $CMD/1.0 tmux-custom-wakatime/1.0" \
  -H "X-Machine-Name: $MACHINE" \
  -d "{\"entity\":\"$DIR\",\"type\":\"app\",\"time\":$NOW,\"created_at\":$NOW,\"project\":\"$PROJECT\"$BRANCH_JSON,\"category\":\"$CMD\",\"machine\":\"$MACHINE\"}" \
  "${API_URL}/compat/wakatime/v1/users/current/heartbeats?api_key=${API_KEY}"
