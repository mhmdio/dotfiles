# Workstation-only dotfiles — configs for apps that need a desktop. Paired with
# packages/workstation.nix: the package and its config ship together, so a
# headless profile pulls in neither.
{ config, lib, ... }:
let
  # Where this repo is checked out. Only needed for the writable symlink below —
  # everything else flows through the store. Change it if you clone elsewhere.
  repo = "${config.home.homeDirectory}/Developer/dotfiles";
in
{
  # WezTerm hot-reloads its config by watching the file, and a store symlink
  # defeats that: every switch repoints ~/.config/wezterm at a NEW store path
  # while the old one — the one actually being watched — never changes. Measured:
  # after a switch the store path moved and the file differed, and the running
  # GUI logged no reload at all, so every edit needed a restart. Installing a
  # writable copy at a stable path means a switch rewrites the very file wezterm
  # is watching. Repo stays source of truth; re-applied each switch.
  home.activation.weztermConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # one-time migration off the old store symlink; after that it's a real dir
    if [ -L "$HOME/.config/wezterm" ]; then
      run rm -f "$HOME/.config/wezterm"
    fi
    run mkdir -p "$HOME/.config/wezterm"
    # overwrite in place rather than rm+create, so the watch survives the switch
    run install -m 0644 ${../config/wezterm/wezterm.lua} "$HOME/.config/wezterm/wezterm.lua"
  '';

  # lazy.nvim's lockfile pins every plugin commit — the one part of this machine
  # nixpkgs doesn't version. Symlinked OUT of the store so `:Lazy update` writes
  # straight into the repo, where it's committed like flake.lock (a store copy
  # would be read-only and updates would fail). Workstation-only: a headless box
  # has no repo to point at.
  xdg.configFile."nvim/lazy-lock.json".source =
    config.lib.file.mkOutOfStoreSymlink "${repo}/home/config/nvim/lazy-lock.json";

  # Zed rewrites its config in-app, so install writable copies (not read-only
  # store symlinks). Repo stays source of truth; re-applied each switch.
  home.activation.zedConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "$HOME/.config/zed"
    run rm -f "$HOME/.config/zed/settings.json" "$HOME/.config/zed/keymap.json"
    run install -m 0644 ${../config/zed/settings.json} "$HOME/.config/zed/settings.json"
    run install -m 0644 ${../config/zed/keymap.json}   "$HOME/.config/zed/keymap.json"
  '';
}
