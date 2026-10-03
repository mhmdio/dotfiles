# Agent Rules 

- The year is 2026. You're an AI coding agent in Ghostty on macOS (Apple Silicon).
- Be concise. Ask when unsure — don't guess. 
- Suggest the simpler approach first.
- Automate anything I do repeatedly. 
- Show the shortcut when one exists.
- Verify options/APIs against current official docs, not memory.
- Don't claim something works until it's confirmed working locally.

## My folders (under ~/Developer)

- `dotfiles` — machine config; the source of truth (see System below).
- `devenv` — client + personal work. Has its own AGENTS.md for that context.
- `LifeHQ` — Obsidian notes / personal knowledge base.

## System — Homebrew (no Nix on this Mac)

Source of truth is `~/Developer/dotfiles`. Edit the repo, not `~/.config`.

- Packages: every CLI, font and GUI app is in `Brewfile` — that list is authoritative.
  Add a `brew`/`cask` line, then `brew bundle --file ~/Developer/dotfiles/Brewfile`. Not mise, not Nix.
- Dotfiles: `home/config/*`, symlinked into `~/.config` by `./install.sh` — live links, so edits apply at once.
- macOS defaults (Dock, Finder, keyboard): `macos.sh`.
- Per-client toolchains: `~/Developer/devenv/<client>/` — a `Brewfile` (installed globally),
  an `envrc` loaded by direnv, and `bin/` helpers.
- Apply: `./install.sh` (or `make apply`). Fresh machine: `./bootstrap.sh`.
- The repo's Nix flake is Linux-only (the homelab server); never run it on the Mac.
- Theme: Catppuccin, auto-follows the macOS light/dark appearance.

## Tools

- Editor: Zed (vim mode, CLI `zed`); sometimes nvim (LazyVim).
- Ghostty terminal · Chrome browser · Obsidian notes · Docker (colima VM) · Raycast (⌘Space).
- Shell: zsh. Helpers live in `home/config/shell/` (e.g. `spf` = files).

## Secrets

- 1Password + `op`. Never write secrets into a repo.

## MCPs & search

- Prefer a CLI over an MCP. GitHub → `gh`. AWS → `aws` (profiles are in `~/.aws/config`; ask which one).
- Enabled MCPs: `linear` (issues) · `vanta` (compliance).
- For library docs and anything online, use the built-in `websearch` / `webfetch`.
  Check the installed source first (lockfile, `node_modules`, vendored code) — it
  is the version actually running, unlike whatever a search returns.

## Docker

- Best practices: <https://docs.docker.com/build/building/best-practices/>
- Compose build/deploy/develop specs: <https://docs.docker.com/reference/compose-file/>
