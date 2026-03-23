#!/bin/sh
# Switch Catppuccin flavor at runtime.
# set -ogq in the plugin theme files means colors only set if unset —
# must wipe all @thm_* vars first so the new palette takes effect.
FLAVOR=$1
tmux show-options -g | awk '/^@thm_/{print $1}' | xargs -I% tmux set -ug %
tmux set -g @catppuccin_flavor "$FLAVOR"
tmux run-shell ~/.tmux/plugins/catppuccin/catppuccin.tmux
tmux set -g status-right ''
