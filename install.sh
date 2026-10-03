#!/usr/bin/env bash
# ============================================================================
# dotfiles install (macOS) — Homebrew packages + config symlinks + agents.
# Idempotent: re-run any time.
#
#   ./install.sh            brew bundle, then link everything
#   ./install.sh --no-brew  link only (fast — no package changes)
#
# Configs are symlinked straight into this checkout, so an edit in the repo is
# live immediately; there is no apply step. Anything already sitting at a
# target that is not our symlink is moved aside to <name>.backup first.
# Linux keeps home-manager: `make linux` / `nix run .#linux`.
#
# Kept bash 3.2-compatible (macOS system bash): no assoc arrays, no mapfile.
# ============================================================================
set -euo pipefail

REPO="$(cd "$(dirname "$0")" && pwd)"
CFG="$REPO/home/config"
XDG="${XDG_CONFIG_HOME:-$HOME/.config}"
AGENTS="$HOME/Library/LaunchAgents"

# --- pretty output (mirrors bootstrap.sh) -----------------------------------
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  B=$'\033[1m'; D=$'\033[2m'; R=$'\033[0m'
  BLUE=$'\033[34m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'
else
  B=; D=; R=; BLUE=; GREEN=; YELLOW=; RED=
fi
step() { printf '\n%s%s▸ %s%s\n' "$B" "$BLUE" "$1" "$R"; }
info() { printf '  %s%s%s\n' "$D" "$1" "$R"; }
ok()   { printf '  %s✓%s %s\n' "$GREEN" "$R" "$1"; }
warn() { printf '  %s!%s %s\n' "$YELLOW" "$R" "$1"; }
die()  { printf '\n  %s✗ %s%s\n' "$RED" "$1" "$R" >&2; exit 1; }

[ "$(uname -s)" = Darwin ] || die "install.sh is macOS-only — Linux uses home-manager (make linux)"

# A literal ~ in the replacement would be tilde-expanded straight back to $HOME.
tilde() { local t='~'; printf '%s' "${1/#$HOME/$t}"; }

# Move whatever is at $1 out of the way, never clobbering an earlier backup.
backup() {
  local bak="$1.backup"
  [ -e "$bak" ] || [ -L "$bak" ] && bak="$1.backup.$(date +%Y%m%d%H%M%S)"
  mv "$1" "$bak"
  warn "moved existing $(tilde "$1") → $(tilde "$bak")"
}

# link <repo source> <target> — symlink, replacing an old link and backing up
# anything real.
link() {
  local src="$1" dst="$2"
  [ -e "$src" ] || die "missing in repo: $src"
  mkdir -p "$(dirname "$dst")"
  if [ -L "$dst" ]; then
    [ "$(readlink "$dst")" = "$src" ] && return 0
    rm "$dst"
  elif [ -e "$dst" ]; then
    backup "$dst"
  fi
  ln -s "$src" "$dst"
  ok "$(tilde "$dst")"
}

# put <source> <target> — a writable COPY, for apps that rewrite their own
# config (lazygit migrates its schema, Zed saves settings in-app). The repo stays
# the source of truth; re-running install.sh re-applies it.
put() {
  mkdir -p "$(dirname "$2")"
  [ -L "$2" ] && rm "$2"
  install -m 0644 "$1" "$2"
  ok "$(tilde "$2") (copy)"
}

# ── packages ────────────────────────────────────────────────────────────────
if [ "${1:-}" != --no-brew ]; then
  step "Homebrew packages"
  command -v brew >/dev/null 2>&1 || [ -x /opt/homebrew/bin/brew ] ||
    die "Homebrew is not installed — run ./bootstrap.sh"
  /opt/homebrew/bin/brew bundle --file "$REPO/Brewfile" --no-upgrade
fi

# ── shell ───────────────────────────────────────────────────────────────────
step "zsh"
link "$REPO/home/zsh/zshenv" "$HOME/.zshenv"
link "$REPO/home/zsh/zprofile" "$HOME/.zprofile"
link "$REPO/home/zsh/zshrc" "$HOME/.zshrc"
link "$CFG/shell" "$XDG/shell"

# ── configs ─────────────────────────────────────────────────────────────────
step "configs"
link "$CFG/git" "$XDG/git"
link "$CFG/starship.toml" "$XDG/starship.toml"
link "$CFG/fzf/fzfrc" "$XDG/fzf/fzfrc"
link "$CFG/bat/config" "$XDG/bat/config"
link "$CFG/btop/btop.conf" "$XDG/btop/btop.conf"
link "$CFG/opencode/AGENTS.md" "$XDG/opencode/AGENTS.md"
link "$CFG/ghostty/config" "$XDG/ghostty/config"
# superfile rewrites its bundled themes into theme/ on upgrade, so link the two
# files rather than the directories.
link "$CFG/superfile/config.toml" "$XDG/superfile/config.toml"
link "$CFG/superfile/theme/terminal.toml" "$XDG/superfile/theme/terminal.toml"

# nvim: file by file so ~/.config/nvim stays a real, writable directory.
# lazy-lock.json links into the repo, so `:Lazy update` lands in git.
for f in init.lua lua lazyvim.json stylua.toml .neoconf.json lazy-lock.json; do
  link "$CFG/nvim/$f" "$XDG/nvim/$f"
done

put "$CFG/lazygit/config.yml" "$XDG/lazygit/config.yml"
put "$CFG/zed/settings.json" "$XDG/zed/settings.json"
put "$CFG/zed/keymap.json" "$XDG/zed/keymap.json"

# gh-dash can't follow the terminal's light/dark palette, so it gets one file
# per flavour (base config + theme block); `ghd` in aliases.zsh picks at launch
# and a bare `gh dash` gets mocha. See home/dotfiles/core.nix for the long why.
for flavour in mocha latte; do
  out="$XDG/gh-dash/config-$flavour.yml"
  mkdir -p "$XDG/gh-dash"
  rm -f "$out"
  cat "$CFG/gh-dash/config.yml" "$CFG/gh-dash/theme-$flavour.yml" >"$out"
done
rm -f "$XDG/gh-dash/config.yml"
cp "$XDG/gh-dash/config-mocha.yml" "$XDG/gh-dash/config.yml"
ok "$(tilde "$XDG/gh-dash")/config{,-mocha,-latte}.yml"

# Karabiner only re-reads its config when its agent restarts.
link "$CFG/karabiner/karabiner.json" "$XDG/karabiner/karabiner.json"
/bin/launchctl kickstart -k "gui/$UID/org.pqrs.service.agent.karabiner_console_user_server" >/dev/null 2>&1 || true

# ── gh ──────────────────────────────────────────────────────────────────────
step "gh"
gh_cfg="$XDG/gh/config.yml"
if [ ! -e "$gh_cfg" ] || [ -L "$gh_cfg" ]; then
  # gh writes to this file itself (`gh config set`), so it's a real file seeded
  # from these settings rather than a link into the repo.
  rm -f "$gh_cfg"
  mkdir -p "$(dirname "$gh_cfg")"
  cat >"$gh_cfg" <<'EOF'
version: '1'
git_protocol: https
editor: nvim
prompt: enabled
prefer_editor_prompt: disabled
aliases:
  co: pr checkout
EOF
  ok "$(tilde "$gh_cfg")"
fi
if gh extension list 2>/dev/null | grep -q 'gh dash'; then
  ok "gh-dash extension"
else
  if gh extension install dlvhdr/gh-dash >/dev/null 2>&1; then
    ok "gh-dash extension installed"
  else
    warn "gh-dash: run \`gh auth login\`, then \`gh extension install dlvhdr/gh-dash\`"
  fi
fi

# ── docker ──────────────────────────────────────────────────────────────────
# Homebrew's compose/buildx are CLI plugins in a dir docker doesn't search by
# default. Merged into the existing config — it also holds registry auths.
step "docker"
dcfg="$HOME/.docker/config.json"
plugins=/opt/homebrew/lib/docker/cli-plugins
if ! command -v jq >/dev/null 2>&1; then
  warn "jq missing — skipped; re-run after brew bundle"
elif [ -s "$dcfg" ] && jq -e --arg d "$plugins" '(.cliPluginsExtraDirs // []) | index($d)' "$dcfg" >/dev/null; then
  ok "compose/buildx plugins"
else
  mkdir -p "$(dirname "$dcfg")"
  [ -s "$dcfg" ] || echo '{}' >"$dcfg"
  tmp="$(mktemp)"
  jq --arg d "$plugins" '.cliPluginsExtraDirs = ((.cliPluginsExtraDirs // []) + [$d])' "$dcfg" >"$tmp" && mv "$tmp" "$dcfg"
  ok "compose/buildx plugins registered in $(tilde "$dcfg")"
fi

# ── launch agents ───────────────────────────────────────────────────────────
step "launch agents"
# Wallpaper: a random one from wallpaper/mac at login and hourly after that.
label="dotfiles.wallpaper-shuffle"
plist="$AGENTS/$label.plist"
mkdir -p "$AGENTS"
cat >"$plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$label</string>
  <key>ProgramArguments</key><array><string>$REPO/home/bin/wallpaper-shuffle</string></array>
  <key>RunAtLoad</key><true/>
  <key>StartInterval</key><integer>3600</integer>
</dict>
</plist>
EOF
/bin/launchctl bootout "gui/$UID/$label" >/dev/null 2>&1 || true
/bin/launchctl bootstrap "gui/$UID" "$plist"
ok "$label"

printf '\n%s%s  ✓ installed%s %s— open a new shell (or: exec zsh)%s\n' "$GREEN" "$B" "$R" "$D" "$R"
