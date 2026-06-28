# Homebrew — `b` command.
#   b up    update brew, list outdated, optionally upgrade, then brew doctor
#   b cl    clean up old versions and cache (brew cleanup --prune=all)
# Requires gum (https://charm.land/libs/).

_b_usage() {
  command cat <<'EOF'
Usage: b <command>

Commands:
  up    Update brew, show outdated, optionally upgrade, then run brew doctor
  cl    Clean up old versions and cache (brew cleanup --prune=all)
EOF
}

_b_require() {
  command -v gum  &>/dev/null || { echo "gum is required: brew install gum" >&2; return 1; }
  command -v brew &>/dev/null || { echo "brew is not installed" >&2; return 1; }
}

_b_up() {
  _b_require || return 1

  gum style \
    --foreground 12 --border-foreground 12 --border double \
    --align center --width 50 --margin "1 0" --padding "1 2" \
    '██████╗ ██████╗ ███████╗██╗    ██╗
██╔══██╗██╔══██╗██╔════╝██║    ██║
██████╔╝██████╔╝█████╗  ██║ █╗ ██║
██╔══██╗██╔══██╗██╔══╝  ██║███╗██║
██████╔╝██║  ██║███████╗╚███╔███╔╝
╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚══╝╚══╝'

  gum spin --show-output --spinner minidot --title "Updating brew..." -- brew update
  printf "\n"

  local outdated
  outdated=$(gum spin --show-output --spinner minidot --title "Checking for outdated brew packages" -- brew outdated)

  if [[ -n "$outdated" ]]; then
    echo "$outdated"
    gum confirm --selected.background=2 --selected.foreground=0 "Upgrade the outdated formulae above?" && brew upgrade
    printf "\n"
  else
    echo "All brew packages are up to date."
    printf "\n"
  fi

  gum spin --show-output --spinner minidot --title "Checking for brew issues..." -- brew doctor
}

_b_cl() {
  _b_require || return 1
  gum spin --show-output --spinner minidot --title "Cleaning up brew..." -- brew cleanup --prune=all
}

b() {
  case "${1:-}" in
    up)                 shift; _b_up "$@" ;;
    cl)                 shift; _b_cl "$@" ;;
    ""|help|-h|--help)  _b_usage ;;
    *) echo "b: unknown command: $1" >&2; _b_usage; return 1 ;;
  esac
}
