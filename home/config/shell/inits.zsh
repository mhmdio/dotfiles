# Interactive init, in load order. Two rules govern this file:
#   1. anything touching PATH or fpath runs BEFORE compinit — the dump is built
#      from fpath, so a late addition is invisible to completion;
#   2. anything that would fork a process per shell gets cached.

_zcache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
[[ -d $_zcache ]] || mkdir -p "$_zcache"

# ── PATH & fpath ─────────────────────────────────────────────────────────────
# Must run before compinit: the dump is built from fpath, so brew's
# site-functions added any later would never reach it.
source "$HOME/.config/shell/path.zsh"

# ── Completion ───────────────────────────────────────────────────────────────
# The only compinit that runs (macOS's /etc/zshrc runs none; home-manager's
# global one is off), and it takes the cheap -C path whenever it can. -C never
# rescans, so the dump is keyed to whatever changes when fpath's contents do —
# a plain `-C` against a fixed filename is what once silently froze completions
# for three months.
#
#   Linux (home-manager): the nix profile's store path — a new generation means
#     a new key. Probe rather than assume: a path that does not exist comes back
#     from `:A` unresolved, keying the dump on the bare username forever.
#   macOS (Homebrew): the mtime of brew's site-functions directory, which moves
#     whenever a formula's completion is linked or unlinked.
_zkey=
for _p in "$HOME/.local/state/nix/profiles/home-manager" "$HOME/.nix-profile"; do
  [[ -e $_p ]] && { _zkey=${${_p:A}:t}; break; }
done
if [[ -z $_zkey && -d ${HOMEBREW_PREFIX:-/nonexistent}/share/zsh/site-functions ]]; then
  zmodload -F zsh/stat b:zstat 2>/dev/null &&
    zstat -A _zm +mtime -- "$HOMEBREW_PREFIX/share/zsh/site-functions" &&
    _zkey="brew-${_zm[1]}"
fi

autoload -Uz compinit
if [[ -n $_zkey ]]; then
  _zdump="$_zcache/zcompdump-$_zkey"
  [[ -s $_zdump ]] || command rm -f "$_zcache"/zcompdump-*(N)  # prune stale keys
  compinit -C -d "$_zdump"
else
  # Nothing reliable to invalidate against, so pay for a real scan rather than
  # serve a dump that can never go stale in a way we would notice.
  compinit -d "$_zcache/zcompdump"
fi
unset _zkey _zdump _zm _p

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
# from $_NIX_ZSH_* on Linux (shared.nix), else Homebrew; guarded so re-sourcing
# won't re-wrap widgets.
if [[ -t 0 && -t 1 ]]; then
  _zas="${_NIX_ZSH_AUTOSUGGESTIONS:-${HOMEBREW_PREFIX:-}/share/zsh-autosuggestions/zsh-autosuggestions.zsh}"
  _zsh_hl="${_NIX_ZSH_SYNTAX_HIGHLIGHTING:-${HOMEBREW_PREFIX:-}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh}"
  (( ${+functions[_zsh_autosuggest_start]} )) || { [[ -r $_zas ]] && source "$_zas"; }
  [[ -n "${ZSH_HIGHLIGHT_VERSION:-}" ]] || { [[ -r $_zsh_hl ]] && source "$_zsh_hl"; }
  unset _zas _zsh_hl
fi

unset -f _zsh_cached_init; unset _zcache  # keep the interactive namespace clean
