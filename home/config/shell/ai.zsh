# AI coding tools — full-permission aliases + the updater.
# Sourced from ~/.config/shell/all
#
#   cc / oc / cx   run that CLI right here, permission prompts off
#   ai-update      update the installed AI CLIs
#
# Worktrees used to live here (`ai <name>` created one and launched a CLI in it).
# Plain `git worktree add` covers it, so the wrapper is gone rather than kept as
# a second, diverging convention.
#
# ─── Tools ───────────────────────────────────────────────────────────────────
# Claude Code .. https://code.claude.com/docs/en/cli-reference
#                full permission: --dangerously-skip-permissions · update: `claude update`
# OpenCode ..... https://opencode.ai/docs/permissions
#                full permission: --auto (auto-approves everything not explicitly
#                denied — opencode has no harder bypass) · update: `opencode upgrade`
# Codex ........ https://developers.openai.com/codex/developer-commands
#                full permission: --yolo (= --dangerously-bypass-approvals-and-sandbox)
#                update: `brew upgrade --cask codex` — it's a cask (hosts/mac.nix), and
#                casks are NOT upgraded on switch (homebrew.onActivation.upgrade = false)
# ─────────────────────────────────────────────────────────────────────────────

# Run one CLI in the current directory with permissions bypassed.
alias cc='claude --dangerously-skip-permissions'
alias oc='opencode --auto'
alias cx='codex --yolo'

# ── updates ──────────────────────────────────────────────────────────────────
# Upgrade one tool via its own updater. Skips when the binary is missing, or when
# Nix owns it: a /nix/store binary is read-only, so its self-updater can't replace
# itself and just stalls — Nix tools upgrade with `make update && make apply`.
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
  if gum spin --show-error --spinner dot --title "Upgrading ${name}..." -- "$@"; then
    gum style --faint "   ✅ ${name} done"
  else
    gum style --foreground 1 "   ✗ ${name} failed"
  fi
}

ai-update() {
  command -v gum &>/dev/null || { echo "gum is required (Nix-managed): make apply" >&2; return 1; }

  gum style --border rounded --padding "0 1" --bold "🤖 AI Tools Upgrade"

  # Order: Claude Code first, then OpenCode, then the rest.
  _ai_upgrade_one "Claude Code" claude   claude update
  _ai_upgrade_one "OpenCode"    opencode opencode upgrade
  _ai_upgrade_one "Codex"       codex    brew upgrade --cask codex

  gum style --bold --foreground 10 "🎉 Done!"
}
