# ============================================================================
# dotfiles — repo operations. Targets auto-detect the platform:
#   macOS  → Homebrew (Brewfile) + install.sh symlinks. No Nix.
#   Linux  → the flake apps (`nix run .#linux` / `.#server`) via apply.sh.
#
#   make            # list every target
#   make apply      # install packages + apply configs for this host
#   make home       # configs only — no package changes
# ============================================================================

UNAME := $(shell uname -s)
ifeq ($(UNAME),Darwin)
  HOST := mac
else
  HOST := linux
  # Linux home target mirrors apply.sh: <user>, or <user>-aarch64 on ARM boxes.
  HM := $(USER)$(if $(filter aarch64 arm64,$(shell uname -m)),-aarch64,)
endif

.DEFAULT_GOAL := help
.PHONY: help apply switch home linux macos outdated build diff generations \
        check test fmt lint update rollback gc cleanup clean bootstrap demo

help: ## List every target
	@printf '\n  \033[1mdotfiles\033[0m — make targets (host: $(HOST))\n\n'
	@awk 'BEGIN{FS=":.*## "} /^[a-z0-9_-]+:.*## /{printf "  \033[36m%-13s\033[0m %s\n",$$1,$$2}' $(MAKEFILE_LIST)
	@printf '\n'

# On a Mac, the Nix-only targets stop here with a pointer instead of a
# "nix: command not found".
define linux_only
@echo "  '$@' is Linux-only (home-manager) — the Mac runs on Homebrew: make apply"
endef

# ── apply ───────────────────────────────────────────────────────────────────
apply: ## Install packages + apply configs (mac: Brewfile + links · linux: home-manager)
ifeq ($(UNAME),Darwin)
	./install.sh
else
	nix run .#linux
endif

switch: apply ## Alias for `apply`

home: ## Configs only, no package changes (mac: relink · linux: home-manager switch)
ifeq ($(UNAME),Darwin)
	./install.sh --no-brew
else
	home-manager switch --flake .#$(HM)
endif

linux: ## Build + activate the Linux home env (nix run .#linux)
ifeq ($(UNAME),Darwin)
	$(linux_only)
else
	nix run .#linux
endif

macos: ## Re-apply macOS defaults — Dock, Finder, keyboard, trackpad (macos.sh)
	./macos.sh

outdated: ## What Homebrew would upgrade, and what's installed but not in the Brewfile
ifeq ($(UNAME),Darwin)
	brew outdated
	@echo "── installed but not declared in Brewfile (remove: brew bundle cleanup --force):"
	@brew bundle cleanup --file Brewfile || true
else
	$(linux_only)
endif

# ── inspect (Linux) ─────────────────────────────────────────────────────────
build: ## Build the home config WITHOUT activating (creates ./result)
ifeq ($(UNAME),Darwin)
	$(linux_only)
else
	home-manager build --flake .#$(HM)
endif

diff: build ## Preview what would change vs the running home env (nvd)
ifeq ($(UNAME),Darwin)
	$(linux_only)
else
	nvd diff ~/.local/state/nix/profiles/home-manager ./result
endif

generations: ## List past home-manager generations
ifeq ($(UNAME),Darwin)
	$(linux_only)
else
	home-manager generations
endif

# ── maintain ────────────────────────────────────────────────────────────────
check: ## nix flake check — lint, fmt, workflows + the home config builds (Linux)
ifeq ($(UNAME),Darwin)
	$(linux_only)
else
	nix flake check
endif

test: ## Isolated bootstrap/apply/shell regressions — no activation (Linux)
ifeq ($(UNAME),Darwin)
	$(linux_only)
else
	@system=$$(nix eval --raw --impure --expr builtins.currentSystem) && \
	  nix build -L --no-link ".#checks.$$system.workflows"
endif

fmt: ## Format every *.nix with nixfmt (nix fmt; Linux)
ifeq ($(UNAME),Darwin)
	$(linux_only)
else
	nix fmt
endif

lint: ## Fast statix lint, no build (Linux)
ifeq ($(UNAME),Darwin)
	$(linux_only)
else
	nix run nixpkgs#statix -- check .
endif

update: ## mac: brew update + upgrade · linux: bump flake inputs (`make update I=nixpkgs`) — both: nvim plugins
ifeq ($(UNAME),Darwin)
	brew update
	brew upgrade
else
	nix flake update $(I)
endif
# nvim's lazy-lock.json links into this checkout, so this writes straight here
# and shows up in `git diff`. Skipped when updating a single flake input:
# `make update I=nixpkgs` means "just that input".
ifeq ($(strip $(I)),)
	@if command -v nvim >/dev/null 2>&1; then nvim --headless '+Lazy! update' +qa; \
	 else echo "  nvim not installed — skipped its plugins"; fi
	@git diff --stat -- home/config/nvim/lazy-lock.json | tail -1
endif

rollback: ## Linux: home-manager has no one-shot rollback — see `make generations`
ifeq ($(UNAME),Darwin)
	$(linux_only)
else
	@echo "home-manager has no one-shot rollback; run 'make generations' and activate that generation manually"
endif

gc: ## mac: brew cleanup · linux: delete old generations + nix GC + store optimise
ifeq ($(UNAME),Darwin)
	brew cleanup --prune=all
else
	sudo nix-collect-garbage -d
	nix-collect-garbage -d
	nix store optimise
endif

clean: ## Remove ./result build symlinks
	rm -f result result-*

cleanup: ## Reclaim disk — docker prune + go/brew/pnpm caches (+ nix GC on Linux; skips missing tools)
	@echo "▸ docker prune (skipped if the daemon is down)…"
	-@command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1 && docker system prune -a --volumes -f
ifneq ($(UNAME),Darwin)
	@echo "▸ nix garbage collection — system + user generations + store optimise…"
	sudo nix-collect-garbage -d
	nix-collect-garbage -d
	nix store optimise
endif
	@echo "▸ tool caches — go / brew / pnpm (skipped if absent)…"
	-@command -v go   >/dev/null 2>&1 && go clean -cache
	-@command -v brew >/dev/null 2>&1 && brew cleanup --prune=all
	-@command -v pnpm >/dev/null 2>&1 && pnpm store prune

# ── setup ───────────────────────────────────────────────────────────────────
bootstrap: ## Fresh machine / full re-provision (runs ./bootstrap.sh)
	./bootstrap.sh

demo: ## Re-record the README showcase gif (needs vhs: brew install vhs)
	vhs .github/demo.tape
