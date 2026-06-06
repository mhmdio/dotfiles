# AI coding tools — `ai` command.
#   ai up   update installed AI CLIs (skips any that aren't installed)
# Order is deliberate: Claude Code first, then OpenCode, then the rest.
# Requires gum (https://charm.land/libs/).
#
# ─── Tools (edit/add lines in _ai_upgrade to change the set or order) ────────
# Claude Code .. https://code.claude.com/docs   (`claude update`)
# OpenCode ..... https://opencode.ai             (`opencode upgrade`)
# Codex ........ https://github.com/openai/codex (`npm update -g @openai/codex`)
# ─────────────────────────────────────────────────────────────────────────────

_ai_usage() {
  cat <<'EOF'
Usage: ai <command>

Commands:
  up    Update installed AI coding tools (Claude Code, OpenCode, Codex)
EOF
}

# Upgrade one tool if its binary is present, otherwise skip with a note.
#   $1 = display name   $2 = binary to check   $3.. = upgrade command
_ai_upgrade_one() {
  local name="$1" bin="$2"; shift 2
  if command -v "$bin" &>/dev/null; then
    gum spin --spinner dot --title "Upgrading ${name}..." -- "$@"
    gum style --faint "   ✅ ${name} done"
  else
    gum style --faint "   ⊘ ${name} not installed — skipped"
  fi
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
