# Linux desktop layer (standalone home-manager): the full workstation profile,
# painted Catppuccin Mocha. For a headless box use home/server.nix instead — same
# theme, core packages only.
{
  imports = [
    ./workstation.nix
    ./theme-mocha.nix
  ];
}
