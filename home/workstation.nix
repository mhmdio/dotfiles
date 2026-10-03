# Workstation profile: the portable core plus everything that assumes a machine
# someone sits in front of — the Linux desktop (linux.nix). The Mac mirrors it in
# the Brewfile. home/server.nix imports shared.nix instead, and that is the whole
# difference between a desktop and the headless profile.
{
  imports = [
    ./shared.nix
    ./packages/workstation.nix
    ./dotfiles/workstation.nix
  ];
}
