#!/usr/bin/env bash
# ============================================================================
# dotfiles apply — pretty wrapper around the rebuild step. Invoked by the flake
# apps (`nix run .#mac` / `.#linux`), or run directly from your checkout:
#
#   nix run .#mac       # sudo darwin-rebuild switch --flake .#mac
#   nix run .#linux     # home-manager switch --flake .#<user> -b backup
#   ./apply.sh mac      # …the same, invoked directly
#
# Pure-bash framing (header / steps / result); nix-output-monitor (nom) renders
# the live build tree. Build logs stay on screen, so a failed switch is still
# debuggable — no full-screen takeover. Falls back to nix's own progress bar
# when nom isn't on PATH yet (e.g. the very first apply, before it's installed).
#
# Kept bash 3.2-compatible (macOS system bash): no `|&`, no assoc arrays.
# ============================================================================
set -uo pipefail

PLATFORM="${1:-}"

# --- pretty output (mirrors bootstrap.sh) -----------------------------------
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  B=$'\033[1m'; D=$'\033[2m'; R=$'\033[0m'
  BLUE=$'\033[34m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'; CYAN=$'\033[36m'
else
  B=; D=; R=; BLUE=; GREEN=; YELLOW=; RED=; CYAN=
fi
step()   { printf '\n%s%s▸ %s%s\n' "$B" "$BLUE" "$1" "$R"; }
info()   { printf '  %s%s%s\n' "$D" "$1" "$R"; }
ok()     { printf '  %s✓%s %s\n' "$GREEN" "$R" "$1"; }
warn()   { printf '  %s!%s %s\n' "$YELLOW" "$R" "$1"; }
rule()   { printf '%s  ────────────────────────────────────────────────%s\n' "$D" "$R"; }
banner() { printf '\n%s%s  dotfiles%s %s— apply%s\n' "$CYAN" "$B" "$R" "$D" "$R"; rule; }
die()    { printf '\n  %s✗ %s%s\n' "$RED" "$1" "$R" >&2; exit "${2:-1}"; }

# Run a rebuild command with live progress. nom if present (pretty build tree),
# else nix's built-in multiline bar. Returns the REBUILD's status, not nom's.
# $1 = verbose|quiet — darwin-rebuild forwards -v to nix, but home-manager's arg
# parser whitelists flags and doesn't pass -v, so use quiet there.
run_with_progress() {
  local verbosity="$1"; shift
  if command -v nom >/dev/null 2>&1; then
    if [ "$verbosity" = verbose ]; then
      "$@" --log-format internal-json -v 2>&1 | nom --json
    else
      "$@" --log-format internal-json 2>&1 | nom --json
    fi
    return "${PIPESTATUS[0]}"
  fi
  warn "nom not on PATH yet — using nix's built-in progress (it'll install this run)"
  "$@" --log-format multiline
}

# Runs against the flake in the current directory — both `nix run .#mac` and a
# direct `./apply.sh mac` invoke us from your dotfiles checkout.
[ -f flake.nix ] || die "run from your dotfiles checkout (no flake.nix in $PWD)"
banner

# Flakes only see git-tracked files; stage so edits aren't silently skipped.
if [ -d .git ]; then
  info "staging tracked changes for the flake…"
  git add -A 2>/dev/null || true
fi

case "$PLATFORM" in
  mac)
    step "apply  .#mac   ·   sudo darwin-rebuild switch"
    info "caching sudo credentials up front (one prompt)…"
    sudo -v || die "sudo authentication failed"
    before="$(readlink -f /run/current-system 2>/dev/null || true)"
    run_with_progress verbose sudo darwin-rebuild switch --flake ".#mac" \
      || die "switch failed — see the build log above" "$?"
    rule
    ok "activated  ${B}.#mac${R}"
    # What changed this switch (package adds/removes/version bumps).
    if command -v nvd >/dev/null 2>&1 && [ -n "$before" ]; then
      after="$(readlink -f /run/current-system 2>/dev/null || true)"
      if [ -n "$after" ] && [ "$before" != "$after" ]; then
        step "changes"
        nvd diff "$before" "$after" || true
      fi
    fi
    ;;
  linux)
    TARGET="${USER:-$(id -un)}"
    # aarch64 boxes build the -aarch64 home config (see flake homeConfigurations).
    case "$(uname -m)" in aarch64 | arm64) TARGET="${TARGET}-aarch64" ;; esac
    step "apply  .#${TARGET}   ·   home-manager switch"
    run_with_progress quiet home-manager switch --flake ".#${TARGET}" -b backup \
      || die "switch failed — see the build log above" "$?"
    rule
    ok "activated  ${B}.#${TARGET}${R}"
    ;;
  *)
    die "usage: ./apply.sh <mac|linux>"
    ;;
esac
