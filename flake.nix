{
  description = "Bottom-up dev machine (Lix → nix-darwin → home-manager → devenv)";

  # Unstable channel: tools track upstream latest (yazi, neovim, …).
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Catppuccin theming, used on the Linux side only (Mocha) — see home/linux.nix.
    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ nixpkgs, ... }:
    let
      # Account to build for, read from a tracked file (pure eval, no --impure).
      # bootstrap.sh stamps it from the running user, so the same repo works for
      # ANY account with no manual edit. Forking = adjust casks only.
      username = import ./username.nix;

      # Headless boxes build for their own service account, not the desktop user
      # — the homelab repo's Ansible run activates `<serverUser>-server-aarch64`
      # on the Hetzner VM as that user. Kept literal (not username.nix) because it
      # names a remote account, which has nothing to do with whoever owns this
      # laptop. apply.sh greps this line, so keep the `serverUser = "…";` shape.
      serverUser = "admin";

      darwinSystem = "aarch64-darwin"; # Apple Silicon
      linuxSystem = "x86_64-linux"; # non-NixOS Linux

      # Host builders + lint/format helpers live in nix/lib.nix so this file is
      # just inputs + outputs. Add a machine by repeating mkDarwin with another
      # hostModule/user (see the WSL example at the bottom).
      lib = import ./nix/lib.nix { inherit inputs; };

      darwinMac = lib.mkDarwin {
        system = darwinSystem;
        hostModule = ./hosts/mac.nix;
        homeModule = ./home/darwin.nix;
        user = username;
      };
      homeMain = lib.mkHome {
        system = linuxSystem;
        user = username;
        modules = [ ./home/linux.nix ];
      };
      homeArm = lib.mkHome {
        system = "aarch64-linux";
        user = username;
        modules = [ ./home/linux.nix ];
      };

      # Headless: core packages + Mocha, no desktop layer (see home/server.nix).
      # Both arches so the profile works on a CX/CPX (x86_64) or a CAX (aarch64);
      # mobot is a cax11, so the -aarch64 name is the one that actually gets used.
      serverMain = lib.mkHome {
        system = linuxSystem;
        user = serverUser;
        modules = [ ./home/server.nix ];
      };
      serverArm = lib.mkHome {
        system = "aarch64-linux";
        user = serverUser;
        modules = [ ./home/server.nix ];
      };
    in
    {
      # `nix flake check`: lint + fmt + a real build of each config. CI runs the
      # cheap lint/fmt checks plus an eval of every config (see
      # .github/workflows/ci.yml); the system builds (.darwin / .home) stay
      # local — `make check`.
      checks.${darwinSystem} = {
        lint = lib.lintFor {
          system = darwinSystem;
          src = ./.;
        };
        fmt = lib.fmtCheckFor {
          system = darwinSystem;
          src = ./.;
        };
        darwin = darwinMac.system;
      };
      checks.${linuxSystem} = {
        lint = lib.lintFor {
          system = linuxSystem;
          src = ./.;
        };
        fmt = lib.fmtCheckFor {
          system = linuxSystem;
          src = ./.;
        };
        home = homeMain.activationPackage;
        server = serverMain.activationPackage;
      };

      # `nix fmt` — nixfmt across all .nix files.
      formatter.${darwinSystem} = lib.fmtFor darwinSystem;
      formatter.${linuxSystem} = lib.fmtFor linuxSystem;

      # `nix run .#mac` / `.#linux` / `.#server` drive the apply.sh wrapper (nom
      # progress + nvd diff) against the flake in your cwd; `.#demo` re-records
      # the showcase gif.
      # The Makefile wraps these (run `make`) alongside check/fmt/lint/update/gc.
      apps =
        let
          darwinPkgs = nixpkgs.legacyPackages.${darwinSystem};
        in
        {
          ${darwinSystem} = {
            mac = {
              type = "app";
              program = "${darwinPkgs.writeShellScript "mac" "exec ${darwinPkgs.bash}/bin/bash ${./apply.sh} mac"}";
            };
            demo = {
              type = "app";
              program = "${darwinPkgs.writeShellScript "demo" "exec ${darwinPkgs.vhs}/bin/vhs .github/demo.tape"}";
            };
          };
        }
        # `nix run .#linux` on both Linux arches (apply.sh picks the matching home
        # config by `uname -m`).
        // nixpkgs.lib.genAttrs [ linuxSystem "aarch64-linux" ] (
          system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
          in
          {
            linux = {
              type = "app";
              program = "${pkgs.writeShellScript "linux" "exec ${pkgs.bash}/bin/bash ${./apply.sh} linux"}";
            };
            server = {
              type = "app";
              program = "${pkgs.writeShellScript "server" "exec ${pkgs.bash}/bin/bash ${./apply.sh} server"}";
            };
          }
        );

      # macOS host (apply: nix run .#mac). Add darwin boxes by repeating mkDarwin
      # with another hostModule/user.
      darwinConfigurations.mac = darwinMac;

      # Linux home env (apply: nix run .#linux) — same shell/tools/dotfiles, no GUI,
      # painted Catppuccin Mocha (see home/linux.nix). Both arches so a Hetzner box
      # builds whether it's x86_64 (CX/CPX) or aarch64 (CAX): use the matching name.
      homeConfigurations.${username} = homeMain;
      homeConfigurations."${username}-aarch64" = homeArm;

      # Headless server env (apply: nix run .#server, or from the homelab repo's
      # Ansible dotfiles role). Same core shell/tools/theme as above, minus the
      # desktop layer — see home/server.nix for exactly what that drops.
      homeConfigurations."${serverUser}-server" = serverMain;
      homeConfigurations."${serverUser}-server-aarch64" = serverArm;

      # WSL2 (roadmap) — full NixOS-in-WSL, not standalone home-manager. Sketch;
      # add `inputs.nixos-wsl.url = "github:nix-community/NixOS-WSL/main";` then:
      #   nixosConfigurations.wsl = nixpkgs.lib.nixosSystem {
      #     system = linuxSystem;
      #     specialArgs = { inherit inputs; username = "youruser"; };
      #     modules = [
      #       inputs.nixos-wsl.nixosModules.default
      #       inputs.home-manager.nixosModules.home-manager
      #       { wsl.enable = true; wsl.defaultUser = "youruser";
      #         home-manager.users.youruser = import ./home/shared.nix; }
      #     ];
      #   };  # inside WSL: sudo nixos-rebuild switch --flake .#wsl
    };
}
