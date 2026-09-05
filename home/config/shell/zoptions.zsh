# Vi key bindings — matches nvim/ghostty copy-mode mental model.
# Esc enters normal mode. (Caps is a plain Ctrl — see karabiner.json.)
bindkey -v
# Wait after ESC before deciding it's a standalone Esc (centiseconds).
# Too low (e.g. 1 = 10ms) and the ESC that prefixes arrow keys (ESC [ A) gets
# read as "enter normal mode" before the rest arrives → arrows break, esp. in
# a multiplexer. 20 (200ms) still feels instant for Esc but lets escape
# sequences through.
export KEYTIMEOUT=20
# Keep familiar Ctrl chords working in vi insert mode
bindkey -M viins '^A' beginning-of-line
bindkey -M viins '^E' end-of-line
bindkey -M viins '^K' kill-line
bindkey -M viins '^W' backward-kill-word
bindkey -M viins '^U' backward-kill-line
bindkey -M viins '^Y' yank
bindkey -M viins '^P' up-line-or-history
bindkey -M viins '^N' down-line-or-history
# Ctrl-R → fzf history widget is bound in ~/.config/shell/fzf.zsh (after the
# widget is defined); it survives this file's `bindkey -v` above.
# In normal mode, v opens $EDITOR with current command
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'v' edit-command-line

# Meta/UTF-8 settings
setopt COMBINING_CHARS

# Case-insensitive completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=* l:|=*'

# NB: no MENU_COMPLETE — it inserts the first match before fzf-tab can open its
# picker (fzf.zsh sets `menu no`, which fzf-tab requires).
setopt AUTO_MENU

# Arrow keys: history search matching current input
bindkey "^[[A" history-search-backward
bindkey "^[[B" history-search-forward
bindkey "^[[C" forward-char
bindkey "^[[D" backward-char

# No CHASE_LINKS: it resolves symlinks on cd, and every ~/.config/* here is a
# home-manager symlink — `cd ~/.config/ghostty` would land in a read-only
# /nix/store/…-hm_ghostty (and show that path in the prompt).

# Do not autocomplete hidden files unless explicitly starting with dot
zstyle ':completion:*' match-hidden-files off

# Show all completions at once (no paging)
zstyle ':completion:*' list-prompt ''
zstyle ':completion:*' select-prompt ''

# Keep completion lists clean (names only); details show in fzf-tab preview pane
zstyle ':completion:*' list-dirs-first true

# Smart completion - look at text after cursor
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END

# No list-colors here: nothing sets LS_COLORS (eza is the ls, and it has its own
# palette), and fzf-tab owns the completion menu anyway — `menu no` in fzf.zsh.

# Share history between sessions. APPEND_HISTORY is already zsh's default, and
# HIST_IGNORE_DUPS is subsumed by the ALL_DUPS form below.
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS

# Remove superfluous blanks before recording
setopt HIST_REDUCE_BLANKS

# Don't execute immediately upon history expansion
setopt HIST_VERIFY

# Extended globbing
setopt EXTENDED_GLOB

# Don't beep on errors
unsetopt BEEP

# Allow comments in interactive shells
setopt INTERACTIVE_COMMENTS

# Change directory by typing directory name
setopt AUTO_CD
