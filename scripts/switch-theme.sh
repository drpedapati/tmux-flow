#!/bin/sh
# Switch Catppuccin flavor at runtime — cache-friendly path.
#
# CRITICAL PERF NOTE: tmux caches the parsed style/format of an option
# ONLY if its string value contains no #{} format references
# (options.c: o->cached = strstr(s, "#{") == NULL).  A style like
# "bg=#{@thm_mantle}" is never cached — format_expand runs on every
# redraw. Multiply by 8 options and high redraw rates (mouse events,
# active TUI panes) and the server pegs at 100% CPU.
#
# So: resolve the palette to literal hex values here, then write those
# directly into status-style / window-status-format / pane-border-style
# etc. No #{@thm_*} references in style strings → fully cacheable.

# Mutex: bail if another instance is already switching.
LOCK="/tmp/tmux-flow-switch-theme-$(id -u).lock"
if ! mkdir "$LOCK" 2>/dev/null; then
    exit 0
fi
trap 'rmdir "$LOCK" 2>/dev/null' EXIT INT TERM

FLAVOR=$1

case "$FLAVOR" in
    latte)
        THM_ROSEWATER="#dc8a78"; THM_FLAMINGO="#dd7878"; THM_PINK="#ea76cb"
        THM_MAUVE="#8839ef";     THM_RED="#d20f39";      THM_MAROON="#e64553"
        THM_PEACH="#fe640b";     THM_YELLOW="#df8e1d";   THM_GREEN="#40a02b"
        THM_TEAL="#179299";      THM_SKY="#04a5e5";      THM_SAPPHIRE="#209fb5"
        THM_BLUE="#1e66f5";      THM_LAVENDER="#7287fd"
        THM_TEXT="#4c4f69";      THM_SUBTEXT_1="#6c6f85"; THM_SUBTEXT_0="#5c5f77"
        THM_OVERLAY_2="#7c7f93"; THM_OVERLAY_1="#8c8fa1"; THM_OVERLAY_0="#9ca0b0"
        THM_SURFACE_2="#acb0be"; THM_SURFACE_1="#bcc0cc"; THM_SURFACE_0="#ccd0da"
        THM_BASE="#eff1f5";      THM_MANTLE="#e6e9ef";   THM_CRUST="#dce0e8"
        ;;
    mocha)
        THM_ROSEWATER="#f5e0dc"; THM_FLAMINGO="#f2cdcd"; THM_PINK="#f5c2e7"
        THM_MAUVE="#cba6f7";     THM_RED="#f38ba8";      THM_MAROON="#eba0ac"
        THM_PEACH="#fab387";     THM_YELLOW="#f9e2af";   THM_GREEN="#a6e3a1"
        THM_TEAL="#94e2d5";      THM_SKY="#89dceb";      THM_SAPPHIRE="#74c7ec"
        THM_BLUE="#89b4fa";      THM_LAVENDER="#b4befe"
        THM_TEXT="#cdd6f4";      THM_SUBTEXT_1="#bac2de"; THM_SUBTEXT_0="#a6adc8"
        THM_OVERLAY_2="#9399b2"; THM_OVERLAY_1="#7f849c"; THM_OVERLAY_0="#6c7086"
        THM_SURFACE_2="#585b70"; THM_SURFACE_1="#45475a"; THM_SURFACE_0="#313244"
        THM_BASE="#1e1e2e";      THM_MANTLE="#181825";   THM_CRUST="#11111b"
        ;;
    *)
        exit 0
        ;;
esac

# Apply everything in ONE tmux source-file batch.  Single server
# round-trip; styles resolved to literal hex so tmux caches them.
TMP=$(mktemp -t tmux-flow-theme.XXXXXX) || exit 0
cat > "$TMP" <<EOF
set -g @catppuccin_flavor "$FLAVOR"

# Keep @thm_* vars available for anything else that reads them (e.g.
# the catppuccin plugin's status widgets if the user enables them).
set -g @thm_rosewater "$THM_ROSEWATER"
set -g @thm_flamingo "$THM_FLAMINGO"
set -g @thm_pink "$THM_PINK"
set -g @thm_mauve "$THM_MAUVE"
set -g @thm_red "$THM_RED"
set -g @thm_maroon "$THM_MAROON"
set -g @thm_peach "$THM_PEACH"
set -g @thm_yellow "$THM_YELLOW"
set -g @thm_green "$THM_GREEN"
set -g @thm_teal "$THM_TEAL"
set -g @thm_sky "$THM_SKY"
set -g @thm_sapphire "$THM_SAPPHIRE"
set -g @thm_blue "$THM_BLUE"
set -g @thm_lavender "$THM_LAVENDER"
set -g @thm_text "$THM_TEXT"
set -g @thm_subtext_1 "$THM_SUBTEXT_1"
set -g @thm_subtext_0 "$THM_SUBTEXT_0"
set -g @thm_overlay_2 "$THM_OVERLAY_2"
set -g @thm_overlay_1 "$THM_OVERLAY_1"
set -g @thm_overlay_0 "$THM_OVERLAY_0"
set -g @thm_surface_2 "$THM_SURFACE_2"
set -g @thm_surface_1 "$THM_SURFACE_1"
set -g @thm_surface_0 "$THM_SURFACE_0"
set -g @thm_base "$THM_BASE"
set -g @thm_mantle "$THM_MANTLE"
set -g @thm_crust "$THM_CRUST"
set -g @thm_bg "$THM_BASE"
set -g @thm_fg "$THM_TEXT"

set -g status-right ""
set -g status-right-length 0

# Styles with LITERAL hex values only — no #{} → cacheable by tmux.
set -g  status-style          "bg=$THM_MANTLE,fg=$THM_TEXT"
set -g  status-left-style     "bg=$THM_SURFACE_1,fg=$THM_TEXT"
set -g  message-style         "fg=$THM_TEAL,bg=default,align=centre"
set -g  message-command-style "fg=$THM_TEAL,bg=default,align=centre"
set -gw window-status-format         "#[fg=$THM_SUBTEXT_0,bg=$THM_SURFACE_1] #I #[fg=$THM_SUBTEXT_0,bg=$THM_SURFACE_0] #W "
set -gw window-status-current-format "#[fg=$THM_BASE,bg=$THM_MAUVE] #I #[fg=$THM_TEXT,bg=$THM_SURFACE_2] #W "
set -g  pane-border-style        "fg=$THM_SURFACE_1"
set -g  pane-active-border-style "fg=$THM_MAUVE"
EOF
tmux source-file "$TMP"
rm -f "$TMP"
