# Workstation profile: the portable core plus everything that assumes a machine
# someone sits in front of. Both desktop entry points import this — darwin.nix
# and linux.nix — so a package added to packages/workstation.nix lands on the Mac
# and a Linux desktop at once. home/server.nix imports shared.nix instead, and
# that is the whole difference between a desktop and the headless profile.
{
  imports = [
    ./shared.nix
    ./packages/workstation.nix
    ./dotfiles/workstation.nix
  ];
}
