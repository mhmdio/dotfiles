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
    in
    {
      # `nix flake check`: lint + a real build of each config.
      checks.${darwinSystem} = {
        lint = lib.lintFor {
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
        home = homeMain.activationPackage;
      };

      # `nix fmt` — nixfmt across all .nix files.
      formatter.${darwinSystem} = lib.fmtFor darwinSystem;
      formatter.${linuxSystem} = lib.fmtFor linuxSystem;

      # `nix run .#mac` / `.#linux` drive the apply.sh wrapper (nom progress + nvd
      # diff) against the flake in your cwd; `.#demo` re-records the showcase gif.
      # The Makefile wraps these (run `make`) alongside check/fmt/lint/update/gc.
      apps.${darwinSystem} =
        let
          pkgs = nixpkgs.legacyPackages.${darwinSystem};
        in
        {
          mac = {
            type = "app";
            program = "${pkgs.writeShellScript "mac" "exec ${pkgs.bash}/bin/bash ${./apply.sh} mac"}";
          };
          demo = {
            type = "app";
            program = "${pkgs.writeShellScript "demo" "exec ${pkgs.vhs}/bin/vhs .github/demo.tape"}";
          };
        };
      # `nix run .#linux` on both Linux arches (apply.sh picks the matching home
      # config by `uname -m`).
      apps.${linuxSystem} =
        let
          pkgs = nixpkgs.legacyPackages.${linuxSystem};
        in
        {
          linux = {
            type = "app";
            program = "${pkgs.writeShellScript "linux" "exec ${pkgs.bash}/bin/bash ${./apply.sh} linux"}";
          };
        };
      apps."aarch64-linux" =
        let
          pkgs = nixpkgs.legacyPackages."aarch64-linux";
        in
        {
          linux = {
            type = "app";
            program = "${pkgs.writeShellScript "linux" "exec ${pkgs.bash}/bin/bash ${./apply.sh} linux"}";
          };
        };

      # macOS host (apply: nix run .#mac). Add darwin boxes by repeating mkDarwin
      # with another hostModule/user.
      darwinConfigurations.mac = darwinMac;

      # Linux home env (apply: nix run .#linux) — same shell/tools/dotfiles, no GUI,
      # painted Catppuccin Mocha (see home/linux.nix). Both arches so a Hetzner box
      # builds whether it's x86_64 (CX/CPX) or aarch64 (CAX): use the matching name.
      homeConfigurations.${username} = homeMain;
      homeConfigurations."${username}-aarch64" = homeArm;

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
