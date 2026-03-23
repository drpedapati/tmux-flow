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

CFG="$HOME/.wakatime.cfg"
[ -f "$CFG" ] || exit 0

API_KEY=$(grep -m 1 -E '^[[:space:]]*api_key[[:space:]]*=' "$CFG" | sed 's/.*=[[:space:]]*//' | tr -d '[:space:]')
[ -z "$API_KEY" ] && exit 0

API_URL=$(grep -m 1 -E '^[[:space:]]*api_url[[:space:]]*=' "$CFG" | sed 's/.*=[[:space:]]*//' | tr -d '[:space:]')
[ -z "$API_URL" ] && API_URL="https://wakatime.com/api"

command -v perl >/dev/null 2>&1 || exit 0

json_quote() {
    printf '%s' "$1" | perl -MJSON::PP -e '
        local $/;
        my $value = <STDIN>;
        print JSON::PP->new->allow_nonref->encode($value);
    '
}

b64_encode() {
    printf '%s' "$1" | base64 | tr -d '\n'
}

b64_decode() {
    printf '%s' "$1" | base64 -d 2>/dev/null || printf '%s' "$1" | base64 -D 2>/dev/null
}

sanitize_header_value() {
    printf '%s' "$1" | tr '\r\n' '  '
}

# Dedup on path+command. Either changing means fire immediately.
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/tmux-flow"
STATE_FILE="$STATE_DIR/wakapi-heartbeat.state"
umask 077
mkdir -p "$STATE_DIR" 2>/dev/null || exit 0

LAST_ENTITY=""
LAST_CMD=""
LAST_TIME=0
if [ -f "$STATE_FILE" ]; then
    LAST_ENTITY=$(b64_decode "$(sed -n '1p' "$STATE_FILE")")
    LAST_CMD=$(b64_decode "$(sed -n '2p' "$STATE_FILE")")
    LAST_TIME=$(sed -n '3p' "$STATE_FILE")
fi

NOW=$(date +%s)
case "$LAST_TIME" in
    ''|*[!0-9]*)
        LAST_TIME=0
        ;;
esac
ELAPSED=$((NOW - LAST_TIME))

[ "$DIR" = "$LAST_ENTITY" ] && [ "$CMD" = "$LAST_CMD" ] && [ "$ELAPSED" -lt 120 ] && exit 0

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
# Note: Wakapi's WakaTime compat endpoint only accepts api_key as a query param;
# Basic auth with UUID keys returns 401. Key in URL is a known limitation.
CMD_HEADER=$(sanitize_header_value "$CMD")
MACHINE_HEADER=$(sanitize_header_value "$MACHINE")

DIR_JSON=$(json_quote "$DIR")
CMD_JSON=$(json_quote "$CMD")
PROJECT_JSON=$(json_quote "$PROJECT")
MACHINE_JSON=$(json_quote "$MACHINE")

PAYLOAD="{\"entity\":$DIR_JSON,\"type\":\"app\",\"time\":$NOW,\"created_at\":$NOW,\"project\":$PROJECT_JSON,\"category\":$CMD_JSON,\"machine\":$MACHINE_JSON"
if [ -n "$BRANCH" ]; then
    BRANCH_JSON=$(json_quote "$BRANCH")
    PAYLOAD="$PAYLOAD,\"branch\":$BRANCH_JSON"
fi
PAYLOAD="$PAYLOAD}"

HTTP_CODE=$(curl -sS -o /dev/null -w '%{http_code}' \
  -X POST \
  -H "Content-Type: application/json" \
  -H "User-Agent: wakatime/15.0.0 (darwin-arm64) ${CMD_HEADER}/1.0 tmux-flow-wakatime/1.0" \
  -H "X-Machine-Name: $MACHINE_HEADER" \
  -d "$PAYLOAD" \
  "${API_URL}/compat/wakatime/v1/users/current/heartbeats?api_key=${API_KEY}")
CURL_STATUS=$?
[ "$CURL_STATUS" -eq 0 ] || exit 0

case "$HTTP_CODE" in
    2??)
        TMP_STATE_FILE="${STATE_FILE}.$$"
        if {
            b64_encode "$DIR"
            printf '\n'
            b64_encode "$CMD"
            printf '\n%s\n' "$NOW"
        } > "$TMP_STATE_FILE" 2>/dev/null && mv -f "$TMP_STATE_FILE" "$STATE_FILE"; then
            exit 0
        fi
        rm -f "$TMP_STATE_FILE"
        ;;
esac

exit 0
