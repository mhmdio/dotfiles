# Claude Code helpers
# Sourced from ~/.config/shell/all
#
# The `cc` alias (claude with permissions bypassed) lives in
# ~/.config/shell/ai.zsh. What's left here is Claude-specific: resuming its
# transcripts.
#
# ─── References / docs used to build this ────────────────────────────────────
# Claude Code CLI reference ... https://code.claude.com/docs/en/cli-reference
#     --resume <id>           resume a past session by id
#     -n, --name <name>       display name for the session
# ─────────────────────────────────────────────────────────────────────────────

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
