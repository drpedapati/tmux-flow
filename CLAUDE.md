# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a custom fork of tmux (drpedapati/tmux) that tracks the official upstream (tmux/tmux). The fork is used for developing, testing, and distributing custom modifications via a Homebrew tap (`drpedapati`). Current version: `next-3.7`.

**Remotes:**
- `origin` → `https://github.com/drpedapati/tmux.git` (this fork)
- `upstream` → `https://github.com/tmux/tmux.git` (official tmux)

## Build Commands

```bash
# Full build from source (requires autoconf, automake, pkg-config, yacc/bison)
sh autogen.sh && ./configure && make

# Rebuild after changes (if configure has already been run)
make

# Clean rebuild
make clean && ./configure && make

# Install
sudo make install

# Build distribution tarball
make dist
```

**Dependencies:** libevent 2.x, ncurses, C compiler (gcc/clang), make, pkg-config, yacc/bison

**Notable configure flags:** `--enable-debug`, `--enable-sixel`, `--enable-utf8proc`, `--enable-utempter`, `--enable-systemd`, `--enable-fuzzing`

## Running Tests

```bash
cd regress && make        # Run all regression tests (sequential, 1s delay between)
cd regress && sh foo.sh   # Run a single test
```

Tests are shell scripts in `regress/`. Expected outputs live in `regress/*.result` and test configs in `regress/conf/`.

## Debugging

```bash
tmux -vv                  # Generate server, client, and output log files in cwd
tmux -Ltest -f/dev/null new   # Run isolated server without loading .tmux.conf
```

Log files: `tmux-server*.log`, `tmux-client*.log`, `tmux-out*.log`

## Code Architecture

The codebase is C (autotools build system). Key structural patterns:

- **Entry points:** `tmux.c` (main), `server.c` (server init/event loop), `client.c` (client)
- **Core header:** `tmux.h` — all major data structures (sessions, windows, panes, grids, screens, etc.)
- **Command implementations:** `cmd-*.c` files (70+), one per tmux command. Parser in `cmd-parse.y`.
- **Terminal I/O:** `tty.c`, `tty-keys.c`, `tty-term.c`, `tty-draw.c`, `tty-acs.c` — terminal drawing and key handling
- **Screen/grid layer:** `screen.c`, `screen-write.c`, `screen-redraw.c`, `grid.c`, `grid-reader.c`, `grid-view.c` — the virtual terminal grid
- **Window modes:** `window-copy.c` (copy mode, largest file), `window-buffer.c`, `window-client.c`, `window-clock.c`, `window-customize.c`, `window-tree.c`
- **Format strings:** `format.c` (format expansion engine, second largest file), `format-draw.c`
- **Options system:** `options.c`, `options-table.c` (all tmux options defined here)
- **Layout engine:** `layout.c`, `layout-set.c`, `layout-custom.c`
- **UI elements:** `popup.c`, `menu.c`, `status.c` (status bar)
- **Server-client protocol:** `server-client.c`, `server-fn.c`, `tmux-protocol.h`
- **OS compatibility:** `osdep-*.c` (per-platform), `compat/` directory (portable implementations of OpenBSD APIs like imsg)
- **Images:** `image.c`, `image-sixel.c`

## Syncing with Upstream

The fork syncs with upstream tmux via the OpenBSD base system. See the `SYNCING` file for the full workflow. Key steps:

1. Fetch from upstream/obsd-tmux remote
2. `git merge obsd-master` into main
3. Resolve conflicts
4. Verify build: `make clean && ./autogen.sh && ./configure && make`

## Homebrew Tap Distribution

The custom build is distributed as `tmux-custom` via the `drpedapati/tools` Homebrew tap.

- **Formula:** `drpedapati/homebrew-tools` repo → `Formula/tmux-custom.rb`
- **Install:** `brew install drpedapati/tools/tmux-custom`
- **Install HEAD (this repo's main branch):** `brew install --HEAD drpedapati/tools/tmux-custom`
- **Conflicts with** stock `tmux` formula

The formula builds with `--enable-sixel` and `--enable-utf8proc`. The stable URL currently points to upstream 3.6a tarball; HEAD builds from `drpedapati/tmux` main branch. When distributing custom patches, use `--HEAD` or update the stable URL/sha256 to point to a custom release.

## Man Page

The man page is `tmux.1` (mdoc format). View with: `nroff -mdoc tmux.1 | less`
