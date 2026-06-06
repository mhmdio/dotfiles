#!/usr/bin/env bash
# ============================================================================
# dotfiles bootstrap — one command on a fresh machine (macOS or Linux):
#
#   curl -fsSL https://raw.githubusercontent.com/mhmdio/dotfiles/main/bootstrap.sh | bash
#
# macOS  → Xcode CLT → Lix → Homebrew → nix-darwin + home-manager → switch
# Linux  → Lix → standalone home-manager → switch  (non-NixOS; no system layer)
#
# Idempotent: re-running refreshes the clone and re-applies. The account to
# build for is auto-stamped from $DOTFILES_USER (defaults to $USER).
# ============================================================================
set -euo pipefail

REPO_URL="${DOTFILES_REPO_URL:-https://github.com/mhmdio/dotfiles}"
REPO_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
DOTFILES_USER="${DOTFILES_USER:-$USER}"
DARWIN_REF="github:nix-darwin/nix-darwin/nix-darwin-25.11"
HM_REF="github:nix-community/home-manager/release-25.11"

# Quieten one-time bootstrap eval noise: enable flakes, allow `or` as an
# identifier (nixpkgs lib still uses it), drop the empty root channels path.
NIX_ENV='export NIX_PATH=
export NIX_CONFIG="extra-experimental-features = nix-command flakes
extra-deprecated-features = or-as-identifier"'

# --- pretty output ----------------------------------------------------------
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  B=$'\033[1m'; D=$'\033[2m'; R=$'\033[0m'
  BLUE=$'\033[34m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; CYAN=$'\033[36m'
else
  B=; D=; R=; BLUE=; GREEN=; YELLOW=; CYAN=
fi
step() { printf '\n%s%s▸ %s%s\n' "$B" "$BLUE" "$1" "$R"; }
info() { printf '  %s%s%s\n' "$D" "$1" "$R"; }
ok()   { printf '  %s✓%s %s\n' "$GREEN" "$R" "$1"; }
warn() { printf '  %s!%s %s\n' "$YELLOW" "$R" "$1"; }
banner() {
  printf '\n%s%s  dotfiles%s %s— declarative dev machine, one command%s\n' \
    "$CYAN" "$B" "$R" "$D" "$R"
  printf '%s  ────────────────────────────────────────────────%s\n' "$D" "$R"
}

OS="$(uname -s)"
banner

# --- Layer -1 (macOS only): Xcode Command Line Tools (git, cc) --------------
if [ "$OS" = "Darwin" ] && ! xcode-select -p >/dev/null 2>&1; then
  step "Xcode Command Line Tools"
  warn "Accept the GUI prompt, then re-run this script."
  xcode-select --install || true
  exit 1
fi

# --- Layer 0: Lix (Nix interpreter + daemon) --------------------------------
step "Nix (Lix)"
if ! command -v nix >/dev/null 2>&1; then
  info "installing Lix…"
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.lix.systems/lix | sh -s -- install
  ok "Lix installed"
else
  ok "already installed"
fi
# Lix's nix-daemon.sh reads $ZSH_VERSION unguarded, so relax nounset while sourcing.
if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
  set +u
  # runtime path, absent at lint time
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  set -u
fi

# --- Layer 1a (macOS only): Homebrew (GUI casks; nix-darwin drives bundle) ---
if [ "$OS" = "Darwin" ]; then
  step "Homebrew (GUI casks)"
  if [ ! -x /opt/homebrew/bin/brew ] && ! command -v brew >/dev/null 2>&1; then
    info "installing Homebrew…"
    NONINTERACTIVE=1 /bin/bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    ok "Homebrew installed"
  else
    ok "already installed"
  fi
  [ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# --- Clone, or refresh an existing clone to the published state -------------
step "Repo"
if [ ! -d "$REPO_DIR/.git" ]; then
  info "cloning $REPO_URL"
  git clone --quiet "$REPO_URL" "$REPO_DIR"
  ok "cloned → $REPO_DIR"
else
  # Reset (not pull): single force-pushed commit means histories diverge.
  git -C "$REPO_DIR" fetch --quiet origin
  git -C "$REPO_DIR" reset --hard --quiet origin/main
  ok "refreshed $REPO_DIR to origin"
fi
cd "$REPO_DIR"

# Stamp the account to build for; the flake reads ./username.nix (pure eval).
{ echo '# Auto-stamped by bootstrap.sh — the account this machine builds for.'
  printf '"%s"\n' "$DOTFILES_USER"; } > username.nix
git add username.nix
ok "building for account: ${B}${DOTFILES_USER}${R}"

# --- Activate ----------------------------------------------------------------
step "Activate"
if [ "$OS" = "Darwin" ]; then
  info "nix-darwin + home-manager (.#mac) — first run downloads a lot, be patient"
  # sudo -H → HOME=/var/root (no '$HOME not owned' warning); NIX_* exported
  # inside the elevated shell so they also reach darwin-rebuild's inner eval.
  sudo -H sh -c "$NIX_ENV"'
    exec nix run "$1#darwin-rebuild" -- switch --flake "$2#mac"
  ' sh "$DARWIN_REF" "$REPO_DIR"
  ok "system activated"
else
  HM_TARGET="$DOTFILES_USER"
  case "$(uname -m)" in aarch64 | arm64) HM_TARGET="${DOTFILES_USER}-aarch64" ;; esac
  info "home-manager (.#$HM_TARGET)"
  eval "$NIX_ENV"
  nix run "$HM_REF" -- switch --flake "$REPO_DIR#$HM_TARGET" -b backup
  ok "home environment activated"
fi

# --- Done -------------------------------------------------------------------
printf '\n%s%s  ✓ dotfiles ready%s\n' "$GREEN" "$B" "$R"
if [ "$OS" = "Darwin" ]; then
  info "opening WezTerm — your themed terminal with the right fonts…"
  open "$HOME/Applications/Home Manager Apps/WezTerm.app" 2>/dev/null \
    || open -a WezTerm 2>/dev/null \
    || warn "open WezTerm yourself for the Nerd-Font icons"
  info "apply future changes with: ${B}nix run .#mac${R}"
else
  info "open a new shell; apply future changes with: ${B}nix run .#linux${R}"
fi
