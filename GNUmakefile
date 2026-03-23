# GNUmakefile — tmux-flow release helpers
# This file takes priority over the autotools Makefile for GNU make.
# Run `make release` for the happy-path release workflow.
# Run `make build` / `make install` to fall through to autotools.

SHELL := /bin/bash
REPO  := drpedapati/tmux-flow
TAP   := /tmp/homebrew-tools
FORMULA := $(TAP)/Formula/tmux-flow.rb

.PHONY: release deploy brew-install version

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
	@echo "==> Committing and pushing..."
	git add -A && git status --short
	@if git diff --cached --quiet; then \
		echo "    (nothing to commit)"; \
	else \
		git commit -m "Release v$(V)"; \
	fi
	git push origin main
	@echo "==> Tagging v$(V)..."
	git tag "v$(V)"
	git push origin "v$(V)"
	@echo "==> Creating GitHub release..."
	gh release create "v$(V)" --repo $(REPO) \
		--title "tmux-flow v$(V)" \
		--generate-notes
	@echo "==> Updating Homebrew formula..."
	$(MAKE) deploy V=$(V)
	@echo "==> Done. Run 'make brew-install' to upgrade locally."

# ── Deploy: update formula URL + sha256, push tap ────────────────────
deploy:
	@if [ -z "$(V)" ]; then echo "Usage: make deploy V=<version>"; exit 1; fi
	@if [ ! -d "$(TAP)" ]; then \
		git clone https://github.com/drpedapati/homebrew-tools.git $(TAP); \
	fi
	cd $(TAP) && git pull --ff-only
	@echo "==> Downloading tarball for sha256..."
	$(eval URL := https://github.com/$(REPO)/archive/refs/tags/v$(V).tar.gz)
	$(eval SHA := $(shell curl -sL "$(URL)" | shasum -a 256 | cut -d' ' -f1))
	@echo "    URL: $(URL)"
	@echo "    SHA: $(SHA)"
	sed -i '' 's|url "https://github.com/$(REPO)/archive/refs/tags/.*"|url "$(URL)"|' $(FORMULA)
	sed -i '' 's|sha256 ".*"|sha256 "$(SHA)"|' $(FORMULA)
	sed -i '' 's|version ".*"|version "$(V)"|' $(FORMULA)
	cd $(TAP) && git add Formula/tmux-flow.rb && \
		git commit -m "tmux-flow v$(V)" && \
		git push origin main

# ── Brew install/upgrade ─────────────────────────────────────────────
brew-install:
	brew update
	brew upgrade drpedapati/tools/tmux-flow || brew install drpedapati/tools/tmux-flow

# ── Show current version info ────────────────────────────────────────
version:
	@echo "Binary:  $$(tmux -V)"
	@echo "Brew:    $$(brew info --json drpedapati/tools/tmux-flow | python3 -c 'import json,sys;print(json.load(sys.stdin)[0]["versions"]["stable"])')"
	@echo "Git tag: $$(git describe --tags --abbrev=0)"
	@echo "HEAD:    $$(git log --oneline -1)"
