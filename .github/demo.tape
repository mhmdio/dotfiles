# vhs tape — a short showcase of the themed environment.
# Regenerate with `nix run .#demo` (no install needed; runs vhs via nix).
# Output (.github/demo.gif) is committed so the README Demo renders on GitHub.
#
# Docs: https://github.com/charmbracelet/vhs

Output .github/demo.gif

Set Shell zsh
Set FontFamily "Maple Mono NF"
Set FontSize 18
Set Width 1200
Set Height 760
Set Theme "Catppuccin Mocha"
Set Padding 24
Set TypingSpeed 60ms

Sleep 1s
Type "fastfetch"
Enter
Sleep 2s
Type "clear"
Enter
Sleep 400ms

Type "eza --tree --level=2 --icons --group-directories-first"
Enter
Sleep 2s
Type "clear"
Enter
Sleep 400ms

Type "bat --style=numbers,header --paging=never flake.nix"
Enter
Sleep 2.5s
Type "clear"
Enter
Sleep 400ms

# yazi — terminal file manager with a live preview pane
Type "yazi"
Enter
Sleep 1.5s
Down@600ms 5
Sleep 1s
Up@600ms 2
Sleep 1s
Type "q"
Sleep 800ms
Type "clear"
Enter
Sleep 400ms

# nvim — editor (Catppuccin theme + statusline)
Type "nvim flake.nix"
Enter
Sleep 2.5s
Down@80ms 14
Sleep 1s
Type "gg"
Sleep 1s
Escape
Type ":q"
Enter
Sleep 800ms
Type "clear"
Enter
Sleep 800ms
