# PATH + fpath, in one place. Idempotent (typeset -U), so it is safe to source
# more than once — and on macOS it has to be: ~/.zshenv sources it for every zsh
# (scripts, editor tasks), ~/.zprofile again because /etc/zprofile's path_helper
# shoves /usr/bin back in front of Homebrew for login shells, and inits.zsh once
# more for interactive shells. On Linux home-manager owns .zshenv, so only the
# inits.zsh call applies there.
#
# Precedence: ~/.opencode/bin (own installer, so `opencode upgrade` works) >
# GNU coreutils > Homebrew > system. On Linux the Nix installer's own shell hook
# puts the home-manager profile (~/.nix-profile/bin) in front of the system.

# Static equivalent of `eval "$(brew shellenv)"`, which forks path_helper.
if [[ -x /opt/homebrew/bin/brew ]]; then
  export HOMEBREW_PREFIX=/opt/homebrew
  export HOMEBREW_CELLAR=/opt/homebrew/Cellar
  export HOMEBREW_REPOSITORY=/opt/homebrew
  [[ ":${INFOPATH:-}:" == *:/opt/homebrew/share/info:* ]] ||
    export INFOPATH="/opt/homebrew/share/info${INFOPATH:+:$INFOPATH}"
  fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
  # gnubin: GNU ls/date/stat/… under their plain names, as Nix used to provide.
  path=(/opt/homebrew/opt/coreutils/libexec/gnubin /opt/homebrew/bin /opt/homebrew/sbin $path)
fi

# (N/) drops ~/go/bin on a machine without Go.
path=(
  "$HOME/.opencode/bin"
  $path
  "$HOME/.local/bin"
  "$HOME/go/bin"(N/)
)
typeset -U path fpath
