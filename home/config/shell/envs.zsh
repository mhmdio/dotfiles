export EDITOR="nvim"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
# PATH order (~/.opencode/bin, ~/.local/bin, Homebrew, …) is owned by path.zsh.
# Both ship their CLI inside the .app bundle. Ghostty's is what snacks.image
# probes for to decide the terminal speaks the kitty graphics protocol.
[[ "$OSTYPE" == darwin* ]] && export PATH="$PATH:/Applications/Obsidian.app/Contents/MacOS:/Applications/Ghostty.app/Contents/MacOS"
# zsh history (HISTFILE/HISTSIZE/SAVEHIST): home/zsh/zshrc on the Mac,
# programs.zsh.history in home/shared.nix on Linux

# fzf env vars (FZF_*) + integration live in ~/.config/shell/fzf.zsh
