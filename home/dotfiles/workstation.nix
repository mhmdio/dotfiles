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
  xdg.configFile."wezterm".source = ../config/wezterm;

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
