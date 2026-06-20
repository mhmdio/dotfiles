# Agent Rules 

- The year is 2026. You're an AI coding agent in WezTerm on macOS (Apple Silicon).
- Be concise. Ask when unsure — don't guess. 
- Suggest the simpler approach first.
- Automate anything I do repeatedly. 
- Show the shortcut when one exists.
- Verify options/APIs against current official docs, not memory.
- Don't claim something works until it's confirmed working locally.

## My folders (under ~/Developer)

- `dotfiles` — pure-Nix machine config; the source of truth (see System below).
- `devenv` — client + personal work. Has its own AGENTS.md for that context.
- `LifeHQ` — Obsidian notes / personal knowledge base.

## System — pure Nix

Declarative machine. Source of truth is the flake at `~/Developer/dotfiles`
(nix-darwin + home-manager, Lix daemon). Edit the repo, then apply — hand edits don't stick.

- Dotfiles: Nix-managed (not chezmoi), symlinked read-only into `~/.config`. Edit in the repo.
- CLI tools: nixpkgs in `home/packages.nix` (not brew, not mise).
- GUI apps: Homebrew casks only, declared in `hosts/mac.nix` — that list is authoritative.
- Per-project toolchains: devenv.sh + direnv, scoped to each project's repo.
- Apply: `nix run .#mac`. Fresh machine: `./bootstrap.sh`.
- Theme: Catppuccin, auto-follows the macOS light/dark appearance.

## Tools

- Editor: Zed (vim mode, CLI `zeditor`); sometimes nvim (LazyVim).
- WezTerm terminal · Chrome browser · Obsidian notes · Docker Desktop · Raycast (⌘Space).
- Shell: zsh. Helpers live in `home/config/shell/` (e.g. `cc` = Claude Code worktree).

## Secrets

- 1Password + `op`. Never write secrets into a repo.

## MCPs & search

- Prefer a CLI over an MCP (e.g. `gh`, not a GitHub MCP).
- `context7` for library docs · `exa` to search online.
- Load the `get-code-context-exa` skill before any code-related web search.

## Docker

- Best practices: <https://docs.docker.com/build/building/best-practices/>
- Compose build/deploy/develop specs: <https://docs.docker.com/reference/compose-file/>
