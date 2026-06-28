# AI coding tools — `ai` command.
#   ai up   update installed AI CLIs (skips ones not installed or Nix-managed)
# Order is deliberate: Claude Code first, then OpenCode, then the rest.
# Requires gum (https://charm.land/libs/).
#
# ─── Tools (edit/add lines in _ai_upgrade to change the set or order) ────────
# Claude Code .. https://code.claude.com/docs   (`claude update`)
# OpenCode ..... https://opencode.ai             (Nix-managed → make update)
# Codex ........ https://github.com/openai/codex (`npm update -g @openai/codex`)
# ─────────────────────────────────────────────────────────────────────────────

_ai_usage() {
  command cat <<'EOF'
Usage: ai <command>

Commands:
  up    Update installed AI coding tools (Claude Code, OpenCode, Codex)
EOF
}

# Upgrade one tool via its self-updater. Skips when the binary is missing, or
# when Nix owns it: a /nix/store binary is read-only, so its self-updater can't
# replace itself and just stalls — Nix tools upgrade with `make update && make apply`.
#   $1 = display name   $2 = binary to check   $3.. = upgrade command
_ai_upgrade_one() {
  local name="$1" bin="$2"; shift 2
  # NB: not `path` — in zsh that's the special array tied to $PATH, and a `local
  # path` would blank PATH inside this function.
  local binpath; binpath="$(command -v "$bin" 2>/dev/null)"
  if [ -z "$binpath" ]; then
    gum style --faint "   ⊘ ${name} not installed — skipped"
    return
  fi
  case "$(readlink -f "$binpath")" in
    /nix/store/*)
      gum style --faint "   ⊘ ${name} is Nix-managed — skip (make update && make apply)"
      return ;;
  esac
  gum spin --spinner dot --title "Upgrading ${name}..." -- "$@"
  gum style --faint "   ✅ ${name} done"
}

_ai_upgrade() {
  command -v gum &>/dev/null || { echo "gum is required: brew install gum" >&2; return 1; }

  gum style --border rounded --padding "0 1" --bold "🤖 AI Tools Upgrade"

  # Order: Claude Code first, then OpenCode, then the rest.
  _ai_upgrade_one "Claude Code" claude   claude update
  _ai_upgrade_one "OpenCode"    opencode opencode upgrade
  _ai_upgrade_one "Codex"       codex    npm update -g @openai/codex

  gum style --bold --foreground 10 "🎉 Done!"
}

ai() {
  case "${1:-}" in
    up)                 shift; _ai_upgrade "$@" ;;
    ""|help|-h|--help)  _ai_usage ;;
    *) echo "ai: unknown command: $1" >&2; _ai_usage; return 1 ;;
  esac
}
