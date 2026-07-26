# Headless server profile — the Hetzner box (`mobot`), driven by the homelab
# repo's Ansible dotfiles role. Same shell, same keybinds, same Mocha palette as
# the Linux desktop; none of the desktop weight.
#
# It imports shared.nix directly rather than workstation.nix, which is the entire
# distinction: no wezterm/zed/1Password, no colima VM, no node/bun/pnpm, no media
# toolchain. Adding a package to packages/workstation.nix therefore never grows
# this closure — you have to opt in here, on purpose.
{ pkgs, ... }:
{
  imports = [
    ./shared.nix
    ./theme-mocha.nix
  ];

  # Server-only additions. lazydocker earns its place because this box's actual
  # workload is compose stacks — it's the one TUI worth having on the far end of
  # an SSH session. The `docker` CLI itself is deliberately absent: the engine and
  # its matching client come from the distro package the docker role installs, and
  # a second CLI on PATH would shadow it at a different version.
  home.packages = [ pkgs.lazydocker ];
}
