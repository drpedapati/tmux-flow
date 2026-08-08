---
name: tmux-flow issue
about: Report a problem with tmux-flow, this fork of tmux
title: ''
labels: ''
assignees: ''

---

### Before you file

tmux-flow is a fork of [tmux](https://github.com/tmux/tmux). If the problem also
happens with stock tmux, please report it
[upstream](https://github.com/tmux/tmux/issues) instead — that is where it will
get fixed.

A quick way to tell them apart: tmux-flow's own behaviour lives in its key
bindings, defaults and Homebrew packaging. Rendering, copy mode, and terminal
handling are almost always upstream.

### What happened

<!-- What you did, what you expected, what happened instead. -->

### Version

<!-- Output of: tmux -V  and  brew list --versions tmux-flow -->

### Platform

<!-- macOS or Linux, version, and arm64 or x86_64. -->

### Config

<!--
Does it still happen with no config at all?

    tmux -L test -f /dev/null new

If you enabled the optional plugins by sourcing tmux-flow.conf, say so.
-->

### Logs

<!--
If useful, run `tmux -vv` and attach the tmux-server-*.log and
tmux-client-*.log files it writes to the current directory.
-->
