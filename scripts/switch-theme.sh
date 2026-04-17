#!/bin/sh
# Switch Catppuccin flavor at runtime.
# set -ogq in the plugin theme files means colors only set if unset —
# must wipe all @thm_* vars first so the new palette takes effect.

# Mutex: if another instance is already switching, bail. Terminals can
# send theme-detection responses in rapid succession, which fires the
# client-*-theme hook multiple times and piles up tmux commands.
LOCK="/tmp/tmux-flow-switch-theme-$(id -u).lock"
if ! mkdir "$LOCK" 2>/dev/null; then
    exit 0
fi
trap 'rmdir "$LOCK" 2>/dev/null' EXIT INT TERM

FLAVOR=$1
tmux show-options -g | awk '/^@thm_/{print $1}' | xargs -I% tmux set -ug %
tmux set -g @catppuccin_flavor "$FLAVOR"
tmux run-shell ~/.tmux/plugins/catppuccin/catppuccin.tmux
tmux set -g status-right ''
tmux set -g status-right-length 0

# Catppuccin's default formats bake hardcoded hex values for fg colors,
# which look great in one flavor and terrible in the other. Rewrite
# them with @thm_* vars so they re-resolve on every flavor switch.
tmux set -g  status-style          "bg=#{@thm_mantle},fg=#{@thm_text}"
tmux set -g  status-left-style     "bg=#{@thm_surface_1},fg=#{@thm_text}"
tmux set -g  message-style         "fg=#{@thm_teal},bg=default,align=centre"
tmux set -g  message-command-style "fg=#{@thm_teal},bg=default,align=centre"
tmux set -gw window-status-format         "#[fg=#{@thm_subtext_0},bg=#{@thm_surface_1}] #I #[fg=#{@thm_subtext_0},bg=#{@thm_surface_0}] #W "
tmux set -gw window-status-current-format "#[fg=#{@thm_base},bg=#{@thm_mauve}] #I #[fg=#{@thm_text},bg=#{@thm_surface_2}] #W "
tmux set -g  pane-border-style        "fg=#{@thm_surface_1}"
tmux set -g  pane-active-border-style "fg=#{@thm_mauve}"
