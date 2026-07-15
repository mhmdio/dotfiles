export EDITOR="nvim"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_STATE_HOME="$HOME/.local/state"
export PATH="$PATH:$HOME/.local/bin"
[[ "$OSTYPE" == darwin* ]] && export PATH="$PATH:/Applications/Obsidian.app/Contents/MacOS"
# zsh history (HISTFILE/HISTSIZE/SAVEHIST) is owned by programs.zsh.history — home/shared.nix

# fzf env vars (FZF_*) + integration live in ~/.config/shell/fzf.zsh
