# `help` — cheatsheet of the modern CLI tools this machine installs: the legacy
# command each one replaces + a copy-paste example to try. Only tools actually on
# PATH are shown, so it always reflects what's installed. Display-only: gum draws
# the banner, ANSI (gum-palette 256 colours) draws the aligned rows. Learn a tool
# in more depth with `tldr <tool>`.
help() {
  emulate -L zsh
  local tool=$'\e[1;38;5;212m' arrow=$'\e[38;5;245m' ex=$'\e[38;5;117m'
  local hdr=$'\e[1;38;5;223m' dim=$'\e[38;5;245m' rst=$'\e[0m'

  if command -v gum &>/dev/null; then
    gum style --border rounded --border-foreground 212 --foreground 212 --bold \
      --padding "0 3" --margin "1 0 0 0" "✦  modern CLI cheatsheet"
  else
    print -r -- ""; print -r -- "  ${tool}✦  modern CLI cheatsheet${rst}"
  fi
  print -r -- "  ${dim}what each replaces · a one-liner to try · 'tldr <tool>' for more${rst}"

  # section | command (what you type) | binary to check | replaces | example
  local cur="" section name check replaces example
  while IFS='|' read -r section name check replaces example; do
    [[ -z "$section" || "$section" == \#* ]] && continue
    command -v "$check" &>/dev/null || continue # only list what's installed
    if [[ "$section" != "$cur" ]]; then
      cur="$section"
      printf '\n  %s%s%s\n' "$hdr" "$section" "$rst"
    fi
    printf '  %s%-9s%s %s← %-15s%s %s%s%s\n' \
      "$tool" "$name" "$rst" "$arrow" "$replaces" "$rst" "$ex" "$example" "$rst"
  done <<'DATA'
files & nav|eza|eza|ls|eza -l --icons --git
files & nav|bat|bat|cat / less|bat flake.nix
files & nav|fd|fd|find|fd ".nix$"
files & nav|z|zoxide|cd|z dotfiles
files & nav|y|yazi|ranger / nnn|y
files & nav|dust|dust|du|dust ~/Downloads
files & nav|duf|duf|df|duf
search & text|rg|rg|grep|rg TODO
search & text|sd|sd|sed|sd foo bar file.txt
search & text|choose|choose|cut / awk|echo a b c | choose 1
git|lg|lazygit|git CLI|lg
git|delta|delta|git diff|git diff
system & monitor|btop|btop|top / htop|btop
system & monitor|viddy|viddy|watch|viddy -n2 date
network|doggo|doggo|dig / nslookup|doggo example.com
network|trip|trip|ping / traceroute|sudo trip example.com
network|bandwhich|bandwhich|iftop / nethogs|sudo bandwhich
network|gping|gping|ping|gping example.com
http & json|xh|xh|curl / httpie|xh httpbin.org/get
http & json|jnv|jnv|raw jq|jnv package.json
shell & docs|starship|starship|PS1 prompt|(already your prompt)
shell & docs|atuin|atuin|Ctrl+R history|press Ctrl-R · atuin stats
shell & docs|tldr|tldr|man|tldr tar
DATA
}
