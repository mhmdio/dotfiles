# ============================================================================
# dotfiles — repo operations. Thin wrappers over the flake apps + bootstrap.sh,
# so `nix run .#mac` / `.#linux` stay the source of truth (apply.sh stages the
# tree, builds via nom, prints the nvd diff). Targets auto-detect macOS vs Linux.
#
#   make            # list every target
#   make apply      # build + activate this host
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
.PHONY: help apply switch mac linux build diff generations \
        check fmt lint update rollback gc clean bootstrap demo

help: ## List every target
	@printf '\n  \033[1mdotfiles\033[0m — make targets (host: $(HOST))\n\n'
	@awk 'BEGIN{FS=":.*## "} /^[a-z0-9_-]+:.*## /{printf "  \033[36m%-13s\033[0m %s\n",$$1,$$2}' $(MAKEFILE_LIST)
	@printf '\n'

# ── apply ───────────────────────────────────────────────────────────────────
apply: ## Build + activate this host (auto-detects mac/linux)
	nix run .#$(HOST)

switch: apply ## Alias for `apply`

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
check: ## nix flake check — statix lint + a real build of every config
	nix flake check

fmt: ## Format every *.nix with nixfmt (nix fmt)
	nix fmt

lint: ## Fast statix lint, no build (nix run nixpkgs#statix)
	nix run nixpkgs#statix -- check .

update: ## Bump flake inputs — all, or one: `make update I=nixpkgs`
	nix flake update $(I)

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

# ── setup ───────────────────────────────────────────────────────────────────
bootstrap: ## Fresh machine / full re-provision (runs ./bootstrap.sh)
	./bootstrap.sh

demo: ## Re-record the README showcase gif (vhs; macOS)
	nix run .#demo
