# GNUmakefile — tmux-flow release helpers
# This file takes priority over the autotools Makefile for GNU make.
# Run `make release` for the happy-path release workflow.
# Run `make build` / `make install` to fall through to autotools.

SHELL := /bin/bash
REPO  := drpedapati/tmux-flow
TAP   := /tmp/homebrew-tools
FORMULA := $(TAP)/Formula/tmux-flow.rb

.PHONY: release deploy bottles brew-install version

# ── Default: fall through to autotools ───────────────────────────────
.DEFAULT_GOAL := autotools-fallthrough
autotools-fallthrough:
	@if [ -f Makefile ]; then $(MAKE) -f Makefile; \
	else echo "Run 'sh autogen.sh && ./configure' first."; exit 1; fi

# Any unknown target delegates to the autotools Makefile.
%:
	@if [ -f Makefile ]; then $(MAKE) -f Makefile $@; \
	else echo "Run 'sh autogen.sh && ./configure' first."; exit 1; fi

# ── Release: commit, tag, update formula, brew upgrade ───────────────
# Usage: make release V=1.2
release:
	@if [ -z "$(V)" ]; then \
		echo "Usage: make release V=<version>  (e.g. make release V=1.2)"; \
		exit 1; \
	fi
	@if [ "$$(git branch --show-current)" != "main" ]; then \
		echo "Refusing release: checkout must be on main."; \
		exit 1; \
	fi
	@if ! git diff --quiet || ! git diff --cached --quiet || \
		[ -n "$$(git status --porcelain --untracked-files=normal)" ]; then \
		echo "Refusing release: worktree and index must be clean."; \
		exit 1; \
	fi
	@echo "==> Preflighting reviewed main and publishing access..."
	git fetch origin main
	@test "$$(git rev-parse HEAD)" = "$$(git rev-parse origin/main)" || \
		{ echo "Refusing release: main must exactly match origin/main."; exit 1; }
	@! git rev-parse -q --verify "refs/tags/v$(V)" >/dev/null || \
		{ echo "Refusing release: local tag v$(V) already exists."; exit 1; }
	@! git ls-remote --exit-code --tags origin "refs/tags/v$(V)" >/dev/null 2>&1 || \
		{ echo "Refusing release: remote tag v$(V) already exists."; exit 1; }
	@! gh release view "v$(V)" --repo $(REPO) >/dev/null 2>&1 || \
		{ echo "Refusing release: GitHub release v$(V) already exists."; exit 1; }
	gh auth status >/dev/null
	@if [ ! -d "$(TAP)" ]; then \
		git clone https://github.com/drpedapati/homebrew-tools.git $(TAP); \
	fi
	cd $(TAP) && git pull --ff-only && git diff --quiet && \
		git diff --cached --quiet && test -f Formula/tmux-flow.rb
	@echo "==> Tagging v$(V)..."
	git tag "v$(V)"
	git push origin "v$(V)"
	@echo "==> Updating Homebrew formula..."
	$(MAKE) deploy V=$(V)
	@echo "==> Creating GitHub release..."
	gh release create "v$(V)" --repo $(REPO) \
		--title "tmux-flow v$(V)" \
		--generate-notes
	@echo "==> Done. Run 'make brew-install' to upgrade locally."

# ── Deploy: update formula URL + sha256, push tap ────────────────────
deploy:
	@if [ -z "$(V)" ]; then echo "Usage: make deploy V=<version>"; exit 1; fi
	@if [ ! -d "$(TAP)" ]; then \
		git clone https://github.com/drpedapati/homebrew-tools.git $(TAP); \
	fi
	cd $(TAP) && git pull --ff-only
	@echo "==> Downloading tarball for sha256..."
	@set -e; \
		url="https://github.com/$(REPO)/archive/refs/tags/v$(V).tar.gz"; \
		tarball=$$(mktemp); trap 'rm -f "$$tarball"' EXIT; \
		curl -fsSL "$$url" -o "$$tarball"; \
		sha=$$({ shasum -a 256 "$$tarball" 2>/dev/null || sha256sum "$$tarball"; } | cut -d' ' -f1); \
		test $${#sha} -eq 64; \
		echo "    URL: $$url"; echo "    SHA: $$sha"; \
		sed 's|url "https://github.com/$(REPO)/archive/refs/tags/.*"|url "'"$$url"'"|' $(FORMULA) > $(FORMULA).tmp; \
		mv $(FORMULA).tmp $(FORMULA); \
		awk -v sha="$$sha" 'BEGIN{done=0} /^  sha256 / && !done {sub(/"[a-f0-9]+"/, "\""sha"\""); done=1} {print}' $(FORMULA) > $(FORMULA).tmp; \
		mv $(FORMULA).tmp $(FORMULA); \
		sed 's|version ".*"|version "$(V)"|' $(FORMULA) > $(FORMULA).tmp; \
		mv $(FORMULA).tmp $(FORMULA); \
		awk '/^  bottle do$$/{s=1} s&&/^  end$$/{s=0;next} !s' $(FORMULA) > $(FORMULA).tmp; \
		mv $(FORMULA).tmp $(FORMULA)
	@echo "==> Dropped any stale bottle block (bottles are pinned per version)."
	cd $(TAP) && git add Formula/tmux-flow.rb && \
		git commit -m "tmux-flow v$(V)" && \
		git push origin main
	@echo
	@echo "    Installs will build from source until you run:"
	@echo "        make bottles V=$(V)"
	@echo

# ── Bottles: build on each platform, upload, register in the formula ─
# Bottles are pinned to a release by root_url, so every new version needs
# new ones. deploy drops the old block so a version bump can never leave
# the formula pointing at bottles that do not exist.
bottles:
	@if [ -z "$(V)" ]; then echo "Usage: make bottles V=<version>"; exit 1; fi
	TAP=$(TAP) bash scripts/publish-bottles.sh $(V)

# ── Brew install/upgrade ─────────────────────────────────────────────
brew-install:
	brew update
	brew upgrade drpedapati/tools/tmux-flow || brew install drpedapati/tools/tmux-flow

# ── Show current version info ────────────────────────────────────────
version:
	@echo "Binary:  $$(tmux -V)"
	@echo "Brew:    $$(brew info --json drpedapati/tools/tmux-flow 2>/dev/null | python3 -c 'import json,sys;print(json.load(sys.stdin)[0]["versions"]["stable"])' 2>/dev/null || echo 'tap not installed (run: brew tap drpedapati/tools)')"
	@echo "Git tag: $$(git describe --tags --abbrev=0)"
	@echo "HEAD:    $$(git log --oneline -1)"
