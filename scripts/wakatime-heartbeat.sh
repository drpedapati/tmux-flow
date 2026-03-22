#!/bin/sh
# Send a WakaTime/Wakapi heartbeat on pane focus.
# Called by the pane-focus-in hook baked into tmux-custom.
# Requires: wakatime-cli (brew install wakatime-cli)
# Config:   ~/.wakatime.cfg  (api_key = your-key-here)
#           For Wakapi: also set api_url = https://your-wakapi-server/api/
DIR="$1"
[ -z "$DIR" ] && exit 0
wakatime-cli --write \
  --entity "$DIR" \
  --entity-type app \
  --plugin "tmux-custom/1.0" \
  2>/dev/null &
