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
alias lwt='lazyworktree'     # git worktree manager TUI
# GitHub PR/issue dashboard TUI (gh extension, via programs.gh). Not an alias
# because gh-dash can't switch flavour by itself: a configured colour is one
# value for BOTH appearances, so the flavour is chosen here, per launch. Why it
# can't follow the terminal palette instead: home/dotfiles/core.nix.
ghd() {
  local flavour=mocha
  if [[ $OSTYPE == darwin* ]] && [[ $(defaults read -g AppleInterfaceStyle 2>/dev/null) != Dark ]]; then
    flavour=latte  # the key is absent in light mode, so a failed read means light
  fi
  gh dash --config "${XDG_CONFIG_HOME:-$HOME/.config}/gh-dash/config-$flavour.yml" "$@"
}
alias lzd='lazydocker'
alias hn='hackernews_tui'    # Hacker News reader TUI (binary is underscored)
alias v='nvim'
alias zed='zeditor'          # nixpkgs zed-editor ships its CLI as `zeditor`
n() { if [[ $# -eq 0 ]]; then nvim .; else nvim "$@"; fi; }
# AI CLIs live in ~/.config/shell/ai.zsh: `cc`/`oc`/`cx` run claude/opencode/codex
# here with permissions bypassed; `ai-update` upgrades all three.
alias reload='exec zsh'      # re-exec the shell cleanly

# No multiplexer: Ghostty's own tabs and splits are the whole story (⌘T, ⌘D,
# ⇧⌘D). Nothing survives closing the window, so long jobs want nohup or a
# launchd agent rather than a detached pane.

# superfile (https://superfile.dev) — file navigation.
# cd_on_quit makes spf write `cd '<dir>'` to its lastdir file on exit (verified
# in its quitSuperfile()); sourcing it HERE — not in a subshell — is what moves
# this shell. `Q` inside spf forces that even with the config off. Directory
# learning doesn't depend on any of it: spf calls zoxide's Add() itself as you
# navigate, and `z` inside spf queries the same database.
#
# The path comes from `spf pl --lastdir-file` rather than being hardcoded:
# superfile resolves it through adrg/xdg, so it moves with XDG_STATE_HOME. Asked
# for after the TUI exits so the extra exec never delays startup.
# --print-last-dir is NOT usable here: it prints to stdout, which is where the
# TUI itself draws.
spf() {
  command spf "$@"
  local last; last="$(command spf pl --lastdir-file 2>/dev/null)"
  [[ -n "$last" && -f "$last" ]] || return
  builtin source "$last"
  command rm -f -- "$last"
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
