# Catppuccin Mocha for the Linux side — desktop (linux.nix) and headless server
# (server.nix) alike, so both look identical over SSH.
#
# catppuccin/nix themes home-manager `programs.*` modules — not raw configs — so
# the tools we want coloured are enabled here through those modules. The Mac never
# imports this file: it keeps its raw dotfiles + OS-appearance auto-switch.
{ inputs, ... }:
{
  imports = [ inputs.catppuccin.homeModules.catppuccin ];

  # Mocha everywhere catppuccin supports; autoEnable themes each program module
  # below (and any programs.* added later) — set explicitly so the upcoming
  # catppuccin/nix default flip is a no-op and the deprecation warning is silenced.
  catppuccin = {
    enable = true;
    autoEnable = true;
    flavor = "mocha";
  };

  # High-visibility CLIs, configured as program modules so catppuccin can theme
  # them. (The Mac gets the same two from the Brewfile, with the raw configs in
  # config/bat and config/btop linked by install.sh.)
  programs.bat.enable = true;
  programs.btop.enable = true;
}
