# fzf: aliases, env, shell integration, fzf-tab, ^R bind. Sourced from inits.zsh
# at the plugin seam (after compinit, before syntax-highlighting) so fzf-tab can
# wrap the completion widget. fd = source, eza/bat = previews.

# ff: fuzzy-find with preview; eff: pick a file and open in $EDITOR
alias ff="fzf --preview '[ -d {} ] && eza -TL2 --icons --color=always {} || bat --style=numbers --color=always {}'"
alias eff='$EDITOR $(ff)'

# ── Environment (sources + look & feel) ──────────────────────────────────────
# Use fd: fast, respects .gitignore, includes hidden, skips .git
export FZF_DEFAULT_COMMAND="fd --hidden --follow --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --follow --exclude .git"

# Look & feel + keybinds live in a file (fzf ≥ 0.47) so edits apply to new runs
# without re-sourcing. Guarded: fzf exits with an error if the var points at a
# missing file (e.g. before the symlink exists on a fresh machine).
_fzf_opts_file="${XDG_CONFIG_HOME:-$HOME/.config}/fzf/fzfrc"
[[ -f "$_fzf_opts_file" ]] && export FZF_DEFAULT_OPTS_FILE="$_fzf_opts_file"
unset _fzf_opts_file

# Ctrl-T: bat preview for files, eza tree for dirs
export FZF_CTRL_T_OPTS="
--preview 'if [ -d {} ]; then eza -TL2 --icons --color=always {}; else bat -n --color=always --line-range :300 {}; fi'
--preview-window='right,60%,border-left'
"

# Alt-C: dir tree preview
export FZF_ALT_C_OPTS="--preview 'eza -TL3 --icons --color=always --group-directories-first {}'"

# Ctrl-R: show full command, Ctrl-Y to copy it
export FZF_CTRL_R_OPTS="
--preview 'echo {}' --preview-window='down,3,wrap'
--bind='ctrl-y:execute-silent(printf %s {2..} | pbcopy)+abort'
--header 'Press CTRL-Y to copy command'
"

# ── Shell integration: completion + key-bindings (bash & zsh) ─────────────────
if command -v fzf &>/dev/null; then
  _fzf_shell_dir=""
  if [[ -n "${_NIX_FZF_SHELL_DIR:-}" && -d "$_NIX_FZF_SHELL_DIR" ]]; then
    _fzf_shell_dir="$_NIX_FZF_SHELL_DIR"          # nix: ${pkgs.fzf}/share/fzf
  elif [[ -d /opt/homebrew/opt/fzf/shell ]]; then
    _fzf_shell_dir="/opt/homebrew/opt/fzf/shell"
  elif [[ -d /usr/share/fzf ]]; then
    _fzf_shell_dir="/usr/share/fzf"
  fi

  if [[ -n "$BASH_VERSION" ]]; then
    [[ -f "$_fzf_shell_dir/completion.bash"   ]] && source "$_fzf_shell_dir/completion.bash"
    [[ -f "$_fzf_shell_dir/key-bindings.bash" ]] && source "$_fzf_shell_dir/key-bindings.bash"
  elif [[ -n "$ZSH_VERSION" && -t 0 && -t 1 ]]; then
    [[ -f "$_fzf_shell_dir/completion.zsh" ]] && source "$_fzf_shell_dir/completion.zsh"
    if [[ -f "$_fzf_shell_dir/key-bindings.zsh" ]]; then
      source "$_fzf_shell_dir/key-bindings.zsh"
      # Ctrl-R → fzf history widget (now that the widget is defined). This binding
      # survives the later `bindkey -v` in zoptions, so vi insert mode keeps it.
      bindkey -M viins '^R' fzf-history-widget
    fi
  fi
  unset _fzf_shell_dir
fi

# ── fzf-tab (zsh, interactive) — MUST load after compinit ─────────────────────
if [[ -n "$ZSH_VERSION" && -t 0 && -t 1 ]]; then
  # Guard the source against double-loading (re-wraps the completion widget);
  # the zstyles below are idempotent so they're safe to re-apply.
  (( ${+functions[fzf-tab-complete]} )) || \
    source "${_NIX_FZF_TAB:-/opt/homebrew/opt/fzf-tab/share/fzf-tab/fzf-tab.zsh}"

  zstyle ':completion:*' menu no                       # required: let fzf-tab handle the menu
  zstyle ':completion:*:descriptions' format '[%d]'    # group headers fzf-tab can switch between
  zstyle ':fzf-tab:*' use-fzf-default-opts yes         # inherit default opts (FZF_DEFAULT_OPTS_FILE)
  zstyle ':fzf-tab:*' switch-group '<' '>'             # jump between completion groups
  zstyle ':fzf-tab:*' fzf-flags --height=80% --layout=reverse --border=rounded
  # Preview: dir tree for directories, bat for files
  zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -TL2 --icons --color=always $realpath'
  zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -TL2 --icons --color=always $realpath'
  zstyle ':fzf-tab:complete:*:*' fzf-preview \
    '[ -d $realpath ] && eza -TL2 --icons --color=always $realpath || bat -n --color=always --line-range :200 $realpath 2>/dev/null'
fi
