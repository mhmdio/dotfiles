export EDITOR="nvim"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export PATH="$PATH:$HOME/.local/bin"
# opencode ships via its own installer so `opencode upgrade` works (see
# home/packages/core.nix) — prepended so it wins over anything in nixpkgs. This
# is the non-interactive path; inits.zsh re-asserts the same order for
# interactive shells, where brew would otherwise prepend itself in front.
export PATH="$HOME/.opencode/bin:$PATH"
# Both ship their CLI inside the .app bundle. Ghostty's is what snacks.image
# probes for to decide the terminal speaks the kitty graphics protocol.
[[ "$OSTYPE" == darwin* ]] && export PATH="$PATH:/Applications/Obsidian.app/Contents/MacOS:/Applications/Ghostty.app/Contents/MacOS"
# zsh history (HISTFILE/HISTSIZE/SAVEHIST) is owned by programs.zsh.history — home/shared.nix

# fzf env vars (FZF_*) + integration live in ~/.config/shell/fzf.zsh
