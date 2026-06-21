# Linux-only layer (standalone home-manager, e.g. a headless server). Imports the
# portable core, then paints the CLI Catppuccin Mocha via catppuccin/nix.
#
# catppuccin/nix themes home-manager `programs.*` modules — not raw configs — so
# the tools we want coloured are enabled here through those modules. The Mac never
# imports this file: it keeps its raw dotfiles + OS-appearance auto-switch.
{ inputs, ... }:
{
  imports = [
    ./shared.nix
    inputs.catppuccin.homeModules.catppuccin
  ];

  # Mocha everywhere catppuccin supports; autoEnable themes each program module
  # below (and any programs.* added later) — set explicitly so the upcoming
  # catppuccin/nix default flip is a no-op and the deprecation warning is silenced.
  catppuccin = {
    enable = true;
    autoEnable = true;
    flavor = "mocha";
    # tmux is themed via the terminal's ANSI palette (see home/tmux.nix); skip the
    # catppuccin plugin so it doesn't reorder plugins (continuum must stay last).
    tmux.enable = false;
  };

  # High-visibility CLIs, configured as program modules so catppuccin can theme
  # them. Binaries still come from packages.nix; their macOS raw configs live in
  # dotfiles.nix, gated to Darwin so there's no collision here.
  programs.bat.enable = true;
  programs.btop.enable = true;
}
