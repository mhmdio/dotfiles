 # ============================================================================
# dotfiles — repo operations. Thin wrappers over the flake apps + bootstrap.sh,
# so `nix run .#mac` / `.#linux` stay the source of truth (apply.sh stages the
# tree, builds via nom, prints the nvd diff). Targets auto-detect macOS vs Linux.
#
#   make            # list every target
#   make apply      # build + activate this host (sudo)
#   make home       # dotfiles only — no sudo
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
.PHONY: help apply switch home mac linux build diff generations \
        check test fmt lint update rollback gc cleanup clean bootstrap demo

help: ## List every target
	@printf '\n  \033[1mdotfiles\033[0m — make targets (host: $(HOST))\n\n'
	@awk 'BEGIN{FS=":.*## "} /^[a-z0-9_-]+:.*## /{printf "  \033[36m%-13s\033[0m %s\n",$$1,$$2}' $(MAKEFILE_LIST)
	@printf '\n'

# ── apply ───────────────────────────────────────────────────────────────────
apply: ## Build + activate this host (auto-detects mac/linux)
	nix run .#$(HOST)

switch: apply ## Alias for `apply`

# home-manager is a nix-darwin module here, so `apply` needs root — but only for
# the system half: /etc, launchd, macOS defaults, and the per-user PACKAGE profile
# (useUserPackages puts it in /etc/profiles/per-user). Editing a dotfile touches
# none of that. nix-darwin's activation ends up exec'ing this very `activate`
# script as the user (home-manager/nix-darwin/default.nix), so running it directly
# is the same activation rather than a second, competing one — including
# --driver-version 1, which is what tells it to leave the Nix profile to the
# system. Same evaluation as `apply` too: the derivation is read out of the darwin
# config, not a parallel homeConfigurations output that could drift from it.
home: ## Apply the user layer only — dotfiles, shell, nvim (no sudo)
ifeq ($(UNAME),Darwin)
	@out=$$(nix build --no-link --print-out-paths \
	  '.#darwinConfigurations.$(HOST).config.home-manager.users.$(USER).home.activationPackage') \
	  && "$$out"/activate --driver-version 1
	@printf '  \033[2mconfig files only — new packages, casks and macOS defaults still need `make apply`\033[0m\n'
else
	home-manager switch --flake .#$(HM)
endif

mac: ## Build + activate the macOS system (nix run .#mac)
	nix run .#mac

linux: ## Build + activate the Linux home env (nix run .#linux)
	nix run .#linux

# ── inspect ─────────────────────────────────────────────────────────────────
build: ## Build this host's config WITHOUT activating (creates ./result)
ifeq ($(UNAME),Darwin)
	darwin-rebuild build --flake .#mac
else
	home-manager build --flake .#$(HM)
endif

diff: build ## Preview what would change vs the running system (nvd)
ifeq ($(UNAME),Darwin)
	nvd diff /run/current-system ./result
else
	nvd diff ~/.local/state/nix/profiles/home-manager ./result
endif

generations: ## List past generations (sudo on macOS — reads the system profile)
ifeq ($(UNAME),Darwin)
	sudo darwin-rebuild --list-generations
else
	home-manager generations
endif

# ── maintain ────────────────────────────────────────────────────────────────
check: ## nix flake check — lint, fmt, workflows + this host's config build
	nix flake check

test: ## Isolated bootstrap/apply/shell regressions — no system activation
	@system=$$(nix eval --raw --impure --expr builtins.currentSystem) && \
	  nix build -L --no-link ".#checks.$$system.workflows"

fmt: ## Format every *.nix with nixfmt (nix fmt)
	nix fmt

lint: ## Fast statix lint, no build (nix run nixpkgs#statix)
	nix run nixpkgs#statix -- check .

update: ## Bump flake inputs + nvim plugins — one input only: `make update I=nixpkgs`
	nix flake update $(I)
# nvim's lazy-lock.json is symlinked out of the store, so this writes straight
# here and shows up in `git diff` next to flake.lock. Skipped when updating a
# single input: `make update I=nixpkgs` means "just that input".
ifeq ($(strip $(I)),)
	@if command -v nvim >/dev/null 2>&1; then nvim --headless '+Lazy! update' +qa; \
	 else echo "  nvim not installed — skipped its plugins"; fi
	@git diff --stat -- home/config/nvim/lazy-lock.json | tail -1
endif

rollback: ## Activate the previous generation
ifeq ($(UNAME),Darwin)
	sudo darwin-rebuild --rollback
else
	@echo "home-manager has no one-shot rollback; run 'make generations' and activate that generation manually"
endif

gc: ## Delete old generations, collect garbage, optimise the store
	sudo nix-collect-garbage -d
	nix-collect-garbage -d
	nix store optimise

clean: ## Remove ./result build symlinks
	rm -f result result-*

cleanup: ## Reclaim disk — docker prune + nix GC + go/brew/pnpm caches (skips missing tools)
	@echo "▸ docker prune (skipped if the daemon is down)…"
	-@command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1 && docker system prune -a --volumes -f
	@echo "▸ nix garbage collection — system + user generations + store optimise…"
	sudo nix-collect-garbage -d
	nix-collect-garbage -d
	nix store optimise
	@echo "▸ tool caches — go / brew / pnpm (skipped if absent)…"
	-@command -v go   >/dev/null 2>&1 && go clean -cache
	-@command -v brew >/dev/null 2>&1 && brew cleanup
	-@command -v pnpm >/dev/null 2>&1 && pnpm store prune

# ── setup ───────────────────────────────────────────────────────────────────
bootstrap: ## Fresh machine / full re-provision (runs ./bootstrap.sh)
	./bootstrap.sh

demo: ## Re-record the README showcase gif (vhs; macOS)
	nix run .#demo
