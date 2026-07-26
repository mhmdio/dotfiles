# Workstation-only dotfiles — configs for apps that need a desktop. Paired with
# packages/workstation.nix: the package and its config ship together, so a
# headless profile pulls in neither.
{ lib, ... }:
{
  xdg.configFile."wezterm".source = ../config/wezterm;

  # Zed rewrites its config in-app, so install writable copies (not read-only
  # store symlinks). Repo stays source of truth; re-applied each switch.
  home.activation.zedConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "$HOME/.config/zed"
    run rm -f "$HOME/.config/zed/settings.json" "$HOME/.config/zed/keymap.json"
    run install -m 0644 ${../config/zed/settings.json} "$HOME/.config/zed/settings.json"
    run install -m 0644 ${../config/zed/keymap.json}   "$HOME/.config/zed/keymap.json"
  '';
}
