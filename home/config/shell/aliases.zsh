# ── Listing (eza · https://eza.rocks) ─────────────────────────
alias ls='eza -lh --group-directories-first --icons=auto'
alias la='ls -a'                                                  # long + hidden
alias lt='eza --tree --level=2 --icons=auto --group-directories-first'

# ── Viewers / search ──────────────────────────────────────────
# bat = cat + syntax highlighting; --paging=never keeps plain `cat` feel
# (bat drops color automatically when piped). https://github.com/sharkdp/bat
alias cat='bat --paging=never'
alias grep='grep --color=auto'
# fzf finders (ff / eff) live in ~/.config/shell/fzf.zsh

# ── Navigation (zoxide · https://github.com/ajeetdsouza/zoxide) ─
alias cd='zd'
zd() {
  if [[ $# -eq 0 ]]; then
    builtin cd ~ && return
  elif [[ -d $1 ]]; then
    builtin cd "$1"
  else
    z "$@" && printf "%s " "->" && pwd || echo "Error: Directory not found"
  fi
}
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# ── Tools ─────────────────────────────────────────────────────
alias top='btop'
alias d='docker'
alias lg='lazygit'
alias ghd='gh-dash'          # GitHub PR/issue dashboard TUI (gh-dash binary, from packages.nix)
alias lzd='lazydocker'
alias hn='hackernews_tui'    # Hacker News reader TUI (binary is underscored)
alias v='nvim'
alias zed='zeditor'          # nixpkgs zed-editor ships its CLI as `zeditor`
n() { if [[ $# -eq 0 ]]; then nvim .; else nvim "$@"; fi; }
alias oc='opencode'          # AI agent (`cc` = Claude Code, see claude.zsh)
alias reload='exec zsh'      # re-exec the shell cleanly

# tmux: `t` = fzf project picker → per-project session (also prefix+f in tmux).
alias t='tmux-sessionizer'
alias ta='tmux attach'
alias tl='tmux ls'

# yazi (https://yazi-rs.github.io) — `y` opens yazi and cd's to its exit dir.
y() {
  local tmp cwd
  tmp="$(mktemp -t yazi-cwd.XXXXXX)"
  yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd < "$tmp"
  [[ -n "$cwd" && "$cwd" != "$PWD" ]] && builtin cd -- "$cwd"
  rm -f -- "$tmp"
}

# ── Git (lazygit `lg` for the TUI; these for quick one-offs) ───
alias g='git'
alias gs='git status'
alias gst='git -c color.status=always status'
alias ga='git add'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias gp='git push'
alias gl='git pull'
alias glog='git log --oneline --graph --decorate'
alias glg='git log --color=always --graph --oneline --decorate'
alias gcm='git commit -m'
alias gcam='git commit -a -m'
