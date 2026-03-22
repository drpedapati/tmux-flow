#!/bin/sh
# Send a Wakapi/WakaTime heartbeat on pane focus via curl.
# Reads api_key and api_url from ~/.wakatime.cfg.
# Runs silently in background — no output, no errors shown.

DIR="$1"
[ -z "$DIR" ] && exit 0

CFG=~/.wakatime.cfg
[ -f "$CFG" ] || exit 0

API_KEY=$(grep -E '^\s*api_key\s*=' "$CFG" | sed 's/.*=\s*//' | tr -d '[:space:]')
API_URL=$(grep -E '^\s*api_url\s*=' "$CFG" | sed 's/.*=\s*//' | tr -d '[:space:]')

[ -z "$API_KEY" ] && exit 0
[ -z "$API_URL" ] && API_URL="https://wakatime.com/api"

PROJECT=$(basename "$DIR")
TIME=$(date +%s)

curl -s -o /dev/null \
  -X POST \
  -H "Content-Type: application/json" \
  -d "{\"entity\":\"$DIR\",\"type\":\"app\",\"time\":$TIME,\"project\":\"$PROJECT\",\"plugin\":\"tmux-custom/1.0\"}" \
  "${API_URL}/compat/wakatime/v1/users/current/heartbeats?api_key=${API_KEY}"
