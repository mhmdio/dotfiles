# Claude Code helpers
# Sourced from ~/.config/shell/all
#
# ─── References / docs used to build this ────────────────────────────────────
# Claude Code worktrees ....... https://code.claude.com/docs/en/worktrees
# Claude Code CLI reference ... https://code.claude.com/docs/en/cli-reference
#   `claude --help` shows the flags used here:
#     -w, --worktree [name]   create a git worktree for the session
#     --tmux[=classic]        tmux session for the worktree (REQUIRES --worktree;
#                             default uses iTerm2, =classic for traditional tmux)
#     -n, --name <name>       display name for the session
#     --dangerously-skip-permissions   bypass permission prompts
# Charm libs (gum) ............ https://charm.land/libs/
# gum (prompts/styling) ....... https://github.com/charmbracelet/gum
#   gum confirm → yes/no (exit 0/1, default affirmative)
#   gum style   → --foreground / --border / --padding for boxes & color
# ─────────────────────────────────────────────────────────────────────────────

# Claude Code: `cc [name]` → optionally a git worktree + named session inside a
# classic tmux session (survives terminal close; permissions bypassed from the
# start). Prompts via gum (https://charm.land/libs/) for a polished UI:
#   • Inside a git repo  → asks whether to spin up a worktree (default yes). If
#     yes, fetches origin + sets origin/HEAD first so the worktree branches off
#     FRESH main (not a stale local HEAD). Upstream auto-sets on first push
#     (push.autoSetupRemote=true).
#   • Outside a git repo → worktree isn't possible, so it offers to run Claude
#     right here without one (instead of erroring out).
# Falls back to plain read prompts if gum isn't installed.
# Docs: https://code.claude.com/docs/en/worktrees  ·  e.g. `cc ecs-alarms`
cc() {
  local name="${1:-}"
  # --tmux requires --worktree, so it's added only on the worktree path below.
  local -a flags=(--dangerously-skip-permissions)
  [[ -n "$name" ]] && flags+=(--name "$name")

  local have_gum=0
  command -v gum &>/dev/null && have_gum=1

  # Small helpers so the gum/plain split lives in one place.
  _cc_confirm() {  # $1 = prompt; returns 0 for yes, 1 for no (default yes)
    if (( have_gum )); then
      gum confirm "$1"
    else
      local REPLY; read -q "REPLY?$1 [Y/n] "; echo
      [[ "$REPLY" != [Nn] ]]
    fi
  }
  _cc_note() {     # $@ = lines of styled informational text
    if (( have_gum )); then
      gum style --foreground 212 "$@"
    else
      printf '%s\n' "$@"
    fi
  }

  if git rev-parse --is-inside-work-tree &>/dev/null; then
    if _cc_confirm "Create a git worktree for this session?"; then
      _cc_note "↻ fetching origin so the worktree branches off fresh main…"
      git fetch --quiet origin 2>/dev/null
      git symbolic-ref -q refs/remotes/origin/HEAD >/dev/null 2>&1 \
        || git remote set-head origin -a >/dev/null 2>&1
      if [[ -n "$name" ]]; then
        claude --worktree "$name" --tmux=classic "${flags[@]}"
      else
        claude --worktree --tmux=classic "${flags[@]}"
      fi
    else
      claude "${flags[@]}"
    fi
    return
  fi

  # Not a git repo — a worktree isn't possible here.
  if (( have_gum )); then
    gum style --border rounded --border-foreground 212 --padding "0 1" \
      "Not a git repository:" "$(pwd)" \
      "" "Worktrees need git, so this session will run without one."
  else
    printf 'Not a git repository: %s\n' "$(pwd)"
  fi
  if _cc_confirm "Run Claude here (no worktree)?"; then
    claude "${flags[@]}"
  else
    echo "Cancelled."
    return 1
  fi
}

# ── claude --resume, but in fzf ───────────────────────────────────────────────
# `ccr` lists past Claude Code sessions in fzf and resumes the chosen one.
# Default: sessions for the current project; `ccr -a` spans every project.
# Newest first; each row shows the session's name (custom title → AI-generated
# title → short id) and its first prompt; the preview pane shows the whole prompt
# history. Resumes in the session's original directory. Transcripts:
#   ~/.claude/projects/<cwd, '/' and '.' → '-'>/<session-id>.jsonl
#
# jq: a transcript's human prompts, skipping slash-commands + meta/tool records.
# Exported so fzf's (sh) preview subshell inherits it.
export _CCR_PROMPTS='
  select(.type=="user" and ((.isMeta // false) | not))
  | .message.content
  | (if type=="string" then . else (map(select(.type? == "text").text) | join(" ")) end)
  | select(test("^\\s*<(command-|local-command|bash-)") | not)
  | select(test("^\\s*Caveat:") | not)
  | gsub("\\s+"; " ") | select(length > 0)'

ccr() {
  emulate -L zsh
  zmodload -F zsh/stat b:zstat 2>/dev/null
  zmodload zsh/datetime 2>/dev/null
  local base="$HOME/.claude/projects"
  local all=0; [[ "$1" == "-a" || "$1" == "--all" ]] && all=1

  # Session files, newest first (zsh glob: .=regular N=nullglob om=mtime-desc).
  local -a files
  if (( all )); then
    files=("$base"/*/*.jsonl(.N.om))
  else
    files=("$base/${${PWD//\//-}//./-}"/*.jsonl(.N.om))
  fi
  if (( ! $#files )); then
    (( all )) && print -u2 "ccr: no Claude sessions found." \
              || print -u2 "ccr: no sessions for $PWD (try: ccr -a)"
    return 1
  fi

  local pick
  pick=$(
    local f when title ident tag; local -a st
    for f in $files; do
      zstat -A st +mtime "$f" 2>/dev/null
      strftime -s when '%m-%d %H:%M' ${st[1]:-0}
      (( all )) && tag="[${${${f:h:t}//-//}:t}] " || tag=""
      # name column: user-set custom title → AI title → short session id.
      ident=$(grep '"type":"custom-title"' "$f" 2>/dev/null | tail -1 | jq -r '.customTitle // empty' 2>/dev/null)
      [[ -n "$ident" ]] || ident=$(grep '"type":"ai-title"' "$f" 2>/dev/null | tail -1 | jq -r '.aiTitle // empty' 2>/dev/null)
      [[ -n "$ident" ]] || ident="${${f:t:r}[1,8]}"
      ident=${ident[1,22]}
      title=$(head -n 80 "$f" | jq -r "$_CCR_PROMPTS" 2>/dev/null | head -1)
      title=${title:-…}
      print -r -- "$f"$'\t'"$when  ${tag}${(r:24:)ident}${title[1,72]}"
    done | fzf --delimiter=$'\t' --with-nth=2 --reverse --border \
               --prompt='resume ❯ ' --preview-window='down,45%,wrap' \
               --preview='jq -r "$_CCR_PROMPTS" {1} 2>/dev/null | tail -n 40'
  ) || return 0
  [[ -n "$pick" ]] || return 0

  local file="${pick%%$'\t'*}"
  local id="${file:t:r}"
  local cwd; cwd=$(head -n 40 "$file" | jq -r 'select(.cwd).cwd' 2>/dev/null | head -1)
  if [[ -n "$cwd" && -d "$cwd" ]]; then
    ( cd "$cwd" && claude --resume "$id" )
  else
    claude --resume "$id"
  fi
}
