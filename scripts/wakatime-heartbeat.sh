#!/bin/sh
# Send a Wakapi/WakaTime heartbeat on pane focus via curl.
# Deduplication: only fires if entity changed OR >120s since last heartbeat
# for the same entity — mirrors WakaTime's own deduplication logic.
# Reads api_key and api_url from ~/.wakatime.cfg.

DIR="$1"
[ -z "$DIR" ] && exit 0

CFG=~/.wakatime.cfg
[ -f "$CFG" ] || exit 0

API_KEY=$(grep -E '^\s*api_key\s*=' "$CFG" | sed 's/.*=\s*//' | tr -d '[:space:]')
[ -z "$API_KEY" ] && exit 0

API_URL=$(grep -E '^\s*api_url\s*=' "$CFG" | sed 's/.*=\s*//' | tr -d '[:space:]')
[ -z "$API_URL" ] && API_URL="https://wakatime.com/api"

# Deduplication: read last entity + timestamp from state file
STATE=/tmp/tmux-wakapi-last
LAST_ENTITY=""
LAST_TIME=0
if [ -f "$STATE" ]; then
    LAST_ENTITY=$(cut -d'|' -f1 "$STATE")
    LAST_TIME=$(cut -d'|' -f2 "$STATE")
fi

NOW=$(date +%s)
ELAPSED=$((NOW - LAST_TIME))

# Skip if same directory and fewer than 120 seconds have passed
[ "$DIR" = "$LAST_ENTITY" ] && [ "$ELAPSED" -lt 120 ] && exit 0

# Record state before firing so rapid switches don't pile up
printf '%s|%s' "$DIR" "$NOW" > "$STATE"

PROJECT=$(basename "$DIR")

curl -s -o /dev/null \
  -X POST \
  -H "Content-Type: application/json" \
  -d "{\"entity\":\"$DIR\",\"type\":\"app\",\"time\":$NOW,\"project\":\"$PROJECT\",\"plugin\":\"tmux-custom/1.0\"}" \
  "${API_URL}/compat/wakatime/v1/users/current/heartbeats?api_key=${API_KEY}"
