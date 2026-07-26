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
    # tmux is themed via the terminal's ANSI palette (see home/tmux.nix); skip the
    # catppuccin plugin so it doesn't reorder plugins (continuum must stay last).
    tmux.enable = false;
  };

  # High-visibility CLIs, configured as program modules so catppuccin can theme
  # them. On macOS these same two come as raw packages + raw configs instead
  # (packages/core.nix and dotfiles/core.nix, both Darwin-gated) — that gate is
  # what keeps the two mechanisms from colliding.
  programs.bat.enable = true;
  programs.btop.enable = true;
}
