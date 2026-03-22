#!/bin/sh
# Send a Wakapi heartbeat on pane focus.
# Captures: project (dir basename), entity (full path), language (running command).
# Deduplicates on path+command pair — switches between claude/zsh in same
# project fire separately. Same path+command: 120s cooldown.

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

PROJECT=$(basename "$DIR")

curl -s -o /dev/null \
  -X POST \
  -H "Content-Type: application/json" \
  -d "{\"entity\":\"$DIR\",\"type\":\"app\",\"time\":$NOW,\"project\":\"$PROJECT\",\"language\":\"$CMD\",\"plugin\":\"tmux-custom/1.0\"}" \
  "${API_URL}/compat/wakatime/v1/users/current/heartbeats?api_key=${API_KEY}"
