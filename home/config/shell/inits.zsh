_shell_name="${ZSH_VERSION:+zsh}"
_shell_name="${_shell_name:-bash}"

# Completion system early, before any compdef.
if [[ -n "$ZSH_VERSION" ]]; then
  mkdir -p "$XDG_CACHE_HOME/zsh" # compinit won't create the dump's parent dir
  autoload -Uz compinit && compinit -C -d "$XDG_CACHE_HOME/zsh/zcompdump"
fi

# No theme glue here: each tool reads the terminal's colors and autoswitches itself.

if command -v starship &>/dev/null; then
  if [[ "$_shell_name" == "bash" ]]; then
    # clear stale readline state so the prompt doesn't smear after SIGQUIT etc.
    __sanitize_prompt() { printf '\r\033[K'; }
    PROMPT_COMMAND="__sanitize_prompt${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
  fi
  eval "$(starship init "$_shell_name")"
fi

command -v zoxide &>/dev/null && eval "$(zoxide init "$_shell_name")"

unset _shell_name

# brew (GUI casks) puts /opt/homebrew first; re-prepend nix so its tools win.
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
  export PATH="/etc/profiles/per-user/$USER/bin:/run/current-system/sw/bin:$PATH"
  [[ -n "$ZSH_VERSION" ]] && typeset -U path
fi

# fzf + fzf-tab: sourced here (after compinit, before the plugins below) because
# fzf-tab must wrap the completion widget and load before syntax-highlighting.
source "$HOME/.config/shell/fzf.zsh"

# Atuin: SQLite-backed shell history on Ctrl-R (replaces fzf's history widget —
# fzf.zsh skips its own ^R bind when atuin is present). --disable-up-arrow keeps
# ↑ as prefix history-search. Sourced after fzf so atuin wins ^R; before the
# zsh-syntax-highlighting plugin (which must stay last). Run `atuin import auto`
# once to backfill existing history.
if [[ -n "$ZSH_VERSION" && -t 0 && -t 1 ]] && command -v atuin &>/dev/null; then
  eval "$(atuin init zsh --disable-up-arrow)"
fi

# Plugins: autosuggestions then syntax-highlighting (must be last). Paths come
# from $_NIX_ZSH_* (shared.nix); guarded so re-sourcing won't re-wrap ZLE widgets.
if [[ -n "$ZSH_VERSION" && -t 0 && -t 1 ]]; then
  (( ${+functions[_zsh_autosuggest_start]} )) || \
    source "${_NIX_ZSH_AUTOSUGGESTIONS:-/opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh}"
  [[ -n "${ZSH_HIGHLIGHT_VERSION:-}" ]] || \
    source "${_NIX_ZSH_SYNTAX_HIGHLIGHTING:-/opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh}"
fi
