source "$HOME/.config/shell/envs.zsh"

# If not running interactively, don't load interactive shell helpers.
[[ $- != *i* ]] && return

source "$HOME/.config/shell/aliases.zsh"
source "$HOME/.config/shell/functions.zsh"
source "$HOME/.config/shell/help.zsh"
source "$HOME/.config/shell/claude.zsh"
source "$HOME/.config/shell/ai.zsh"
[[ "$OSTYPE" == darwin* ]] && source "$HOME/.config/shell/brew.zsh"
source "$HOME/.config/shell/inits.zsh"
