# Vi key bindings — matches nvim/wezterm copy-mode mental model.
# Esc enters normal mode; Caps double-tap = Esc via Karabiner.
bindkey -v
# Wait after ESC before deciding it's a standalone Esc (centiseconds).
# Too low (e.g. 1 = 10ms) and the ESC that prefixes arrow keys (ESC [ A) gets
# read as "enter normal mode" before the rest arrives → arrows break, esp. in
# tmux. 20 (200ms) still feels instant for Esc but lets escape sequences through.
# (Pairs with `escape-time 10` in ~/.config/tmux/tmux.conf.)
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

# Show all completions immediately without needing to press tab twice
setopt MENU_COMPLETE
setopt AUTO_MENU

# Arrow keys: history search matching current input
bindkey "^[[A" history-search-backward
bindkey "^[[B" history-search-forward
bindkey "^[[C" forward-char
bindkey "^[[D" backward-char

# Mark symlinked directories (add trailing slash)
setopt CHASE_LINKS

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

# Colored completion listings
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Additional zsh-specific enhancements
# Share history between sessions
setopt SHARE_HISTORY

# Append to history file, don't overwrite
setopt APPEND_HISTORY

# Don't record duplicate commands
setopt HIST_IGNORE_DUPS
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
