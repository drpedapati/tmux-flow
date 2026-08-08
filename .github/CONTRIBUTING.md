## Contributing to tmux-flow

tmux-flow is a fork of [tmux](https://github.com/tmux/tmux) that adds
opinionated defaults and Homebrew packaging. Where to send things:

- **A problem with tmux-flow's bindings, defaults, or Homebrew formula** —
  open an issue or pull request [here](https://github.com/drpedapati/tmux-flow/issues).
- **A problem that also happens with stock tmux** — report it
  [upstream](https://github.com/tmux/tmux/issues). It will get fixed there, and
  this fork picks it up on the next sync. Check by running
  `tmux -L test -f /dev/null new`, which starts tmux with no configuration.
- **The Homebrew formula itself** lives in a separate repository:
  [drpedapati/homebrew-tools](https://github.com/drpedapati/homebrew-tools).

Please do not send tmux-flow issues to the upstream tmux mailing list; the tmux
maintainers do not maintain this fork.

The rest of this document is upstream tmux's guidance on writing a good bug
report. It is worth reading, and applies here too.

---

## What should I do before opening an issue?

Before opening an issue, please ensure that:

- Your problem is a specific problem or question or suggestion, not a general
  complaint.

- `$TERM` inside tmux is screen, screen-256color, tmux or tmux-256color. Check
  by running `echo $TERM` inside tmux.

- You can reproduce the problem with the latest tmux release, or a build from
  Git master.

- Your question or issue is not covered [in the
  manual](https://man.openbsd.org/tmux.1) (run `man tmux`).

- Your problem is not mentioned in [the CHANGES
  file](https://raw.githubusercontent.com/tmux/tmux/master/CHANGES).

- Nobody else has opened the same issue recently.

## What should I include in an issue?

Please include the output of:

~~~bash
uname -sp && tmux -V && echo $TERM
~~~

Also include:

- Your platform (Linux, macOS, or whatever).

- A brief description of the problem with steps to reproduce.

- A minimal tmux config, if you can't reproduce without a config.

- Your terminal, and `$TERM` inside and outside of tmux.

- Logs from tmux (see below). Please attach logs to the issue directly rather
  than using a download site or pastebin. Put in a zip file if necessary.

- At most one or two screenshots, if helpful.

## How do I test without a .tmux.conf?

Run a separate tmux server with `-f/dev/null` to skip loading `.tmux.conf`:

~~~bash
tmux -Ltest kill-server
tmux -Ltest -f/dev/null new
~~~

## How do I get logs from tmux?

Add `-vv` to tmux to create three log files in the current directory. If you can
reproduce without a configuration file:

~~~bash
tmux -Ltest kill-server
tmux -vv -Ltest -f/dev/null new
~~~

Or if you need your configuration:

~~~bash
tmux kill-server
tmux -vv new
~~~

The log files are:

- `tmux-server*.log`: server log file.

- `tmux-client*.log`: client log file.

- `tmux-out*.log`: output log file.

Please attach the log files to your issue.

## What does it mean if an issue is closed?

All it means is that work on the issue is not planned for the near future. See
the issue's comments to find out if contributions would be welcome.
