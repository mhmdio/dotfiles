# Interactive init, in load order. Two rules govern this file:
#   1. anything touching PATH or fpath runs BEFORE compinit — the dump is built
#      from fpath, so a late addition is invisible to completion;
#   2. anything that would fork a process per shell gets cached.

_zcache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
[[ -d $_zcache ]] || mkdir -p "$_zcache"

# ── PATH & fpath ─────────────────────────────────────────────────────────────
# Static equivalent of `eval "$(brew shellenv)"`, which cost ~31ms and forked
# path_helper a second time on top. /opt/homebrew/etc/paths contains exactly
# bin + sbin, so this prepend is what path_helper produced — verified, not
# assumed. The fpath line is the reason this block moved above compinit: it used
# to run after, so brew's completions could never reach the dump.
if [[ -x /opt/homebrew/bin/brew ]]; then
  export HOMEBREW_PREFIX=/opt/homebrew
  export HOMEBREW_CELLAR=/opt/homebrew/Cellar
  export HOMEBREW_REPOSITORY=/opt/homebrew
  export INFOPATH="/opt/homebrew/share/info${INFOPATH:+:$INFOPATH}"
  fpath=(/opt/homebrew/share/zsh/site-functions $fpath)
  path=(/opt/homebrew/bin /opt/homebrew/sbin $path)
fi

# Precedence, decided here so it lives in one place: ~/.opencode/bin (its own
# installer, see envs.zsh) beats nix, and nix beats brew. envs.zsh sets the
# opencode entry for non-interactive shells too; re-asserting it here is what
# survives brew's prepend above. typeset -U keeps the first copy of each.
path=("$HOME/.opencode/bin" /etc/profiles/per-user/"$USER"/bin /run/current-system/sw/bin $path)
typeset -U path fpath

# ── Completion ───────────────────────────────────────────────────────────────
# The only compinit that runs: the system-wide one is off (programs.zsh
# .enableGlobalCompInit, hosts/mac.nix), so this replaces a full ~545ms scan.
# The dump is keyed to the nix profile's store path, which is the one thing that
# changes when fpath changes — so a switch rebuilds it exactly once and every
# later shell takes the cheap -C path. A plain `-C` against a fixed filename is
# what silently froze completions for three months: new tools were never picked
# up because -C never rescans.
#
# The profile sits in a different place per platform: nix-darwin + home-manager
# use /etc/profiles/per-user, standalone home-manager on Linux uses
# ~/.nix-profile. Probe rather than assume — a path that does not exist comes
# back from `:A` unresolved, which would key the dump on the bare username and
# so never change it again.
_zprof=
for _p in /etc/profiles/per-user/$USER "$HOME/.local/state/nix/profiles/home-manager" "$HOME/.nix-profile"; do
  [[ -e $_p ]] && { _zprof=${_p:A}; break; }
done

autoload -Uz compinit
if [[ -n ${_zprof:t} ]]; then
  _zdump="$_zcache/zcompdump-${_zprof:t}"
  [[ -s $_zdump ]] || command rm -f "$_zcache"/zcompdump-*(N)  # prune older generations
  compinit -C -d "$_zdump"
else
  # No nix profile to key on (this file is normally deployed by one). Nothing
  # reliable to invalidate against, so pay for a real scan rather than serve a
  # dump that can never go stale in a way we would notice.
  compinit -d "$_zcache/zcompdump"
fi
unset _zprof _zdump _p

# ── Cached tool inits ────────────────────────────────────────────────────────
# `<tool> init zsh` output is static (verified identical across runs) but each
# fork cost 23-29ms. Cache it, keyed on the binary's store path so a version
# bump regenerates on its own and there is nothing to invalidate by hand.
_zsh_cached_init() {  # $1 = binary (also cache name); "$@" = command to capture
  local bin=${commands[$1]}
  [[ -n $bin ]] || return 0
  local f="$_zcache/init-$1-${${bin:A:h:h}:t}.zsh"
  if [[ ! -s $f ]]; then
    command rm -f "$_zcache"/init-"$1"-*(N)
    "$@" >| "$f" 2>/dev/null || { command rm -f "$f"; return 0; }
  fi
  source "$f"
}

_zsh_cached_init starship init zsh
_zsh_cached_init zoxide init zsh

# fzf + fzf-tab: after compinit (fzf-tab wraps the completion widget), before
# syntax-highlighting.
source "$HOME/.config/shell/fzf.zsh"

# Atuin: SQLite-backed history on Ctrl-R (fzf.zsh skips its own ^R bind when
# atuin is present). --disable-up-arrow keeps ↑ as prefix search. After fzf so
# atuin wins ^R; before syntax-highlighting, which must stay last. Run
# `atuin import auto` once to backfill.
if [[ -t 0 && -t 1 ]]; then
  _zsh_cached_init atuin init zsh --disable-up-arrow
fi

# Plugins: autosuggestions then syntax-highlighting (must be last). Paths come
# from $_NIX_ZSH_* (shared.nix); guarded so re-sourcing won't re-wrap widgets.
if [[ -t 0 && -t 1 ]]; then
  (( ${+functions[_zsh_autosuggest_start]} )) || \
    source "$_NIX_ZSH_AUTOSUGGESTIONS"
  [[ -n "${ZSH_HIGHLIGHT_VERSION:-}" ]] || \
    source "$_NIX_ZSH_SYNTAX_HIGHLIGHTING"
fi

unset -f _zsh_cached_init; unset _zcache  # keep the interactive namespace clean
