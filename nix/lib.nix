# Flake helpers: host builders + lint/format derivations. Kept out of flake.nix
# so that file stays inputs + outputs wiring. Path arguments (hostModule,
# homeModule, src, modules) are passed in from the flake root so their relative
# references resolve there, not against this nix/ directory.
{ inputs }:
let
  inherit (inputs) nixpkgs nix-darwin home-manager;

  # Empty on purpose — the seam both builders wire up, so a package override is
  # one entry here instead of a change to mkDarwin and mkHome. (Last occupant: a
  # sqlfmt pname workaround, dropped once nixpkgs fixed it upstream.)
  overlays = [ ];

  # Both standalone entry points carry the pinned driver, even before the first
  # generation installs home-manager. Leave Nix itself to the host's Lix install.
  mkHomeApp =
    {
      system,
      platform,
      src,
    }:
    let
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      type = "app";
      program = "${pkgs.writeShellScript platform ''
        export PATH="${home-manager.packages.${system}.home-manager}/bin:$PATH"
        exec ${pkgs.bash}/bin/bash ${src + "/apply.sh"} ${platform}
      ''}";
    };
in
{
  inherit mkHomeApp;

  # macOS: full system (nix-darwin) + that user's home-manager.
  mkDarwin =
    {
      system,
      hostModule,
      homeModule,
      user,
    }:
    nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = {
        inherit inputs;
        username = user;
      };
      modules = [
        hostModule
        { nixpkgs.overlays = overlays; }
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = {
            inherit inputs;
            username = user;
          };
          home-manager.users.${user} = import homeModule;
          home-manager.backupFileExtension = "backup";
        }
      ];
    };

  # Standalone home-manager (non-NixOS Linux / WSL) — no system layer. allowUnfree
  # mirrors the macOS side (hosts/mac); without it the build fails on _1password-cli.
  mkHome =
    {
      system,
      user,
      modules,
    }:
    home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs {
        inherit system overlays;
        config.allowUnfree = true;
      };
      extraSpecialArgs = {
        inherit inputs;
        username = user;
      };
      inherit modules;
    };

  # `nix flake check`: dead-code + anti-pattern + shell lint. `src` is the flake
  # root so deadnix/statix scan the repo and shellcheck finds the scripts.
  lintFor =
    { system, src }:
    let
      pkgs = nixpkgs.legacyPackages.${system};
    in
    pkgs.runCommandLocal "dotfiles-lint"
      {
        nativeBuildInputs = [
          pkgs.deadnix
          pkgs.statix
          pkgs.shellcheck
        ];
      }
      ''
        cd ${src}
        deadnix --fail .
        statix check .
        shellcheck bootstrap.sh apply.sh
        touch "$out"
      '';

  # Exercise the real scripts with disposable Git repos and fake rebuilds.
  # Build the same home-app wrappers natively so macOS can test first-run CLI
  # wiring too, without needing a Linux builder or activating a real profile.
  workflowsFor =
    { system, src }:
    let
      pkgs = nixpkgs.legacyPackages.${system};
      app = platform: mkHomeApp { inherit system src platform; };
    in
    pkgs.runCommandLocal "dotfiles-workflows"
      {
        nativeBuildInputs = with pkgs; [
          bash
          coreutils
          git
          gnugrep
          gnused
          python3
          zsh
        ];
        DOTFILES_TEST_LINUX_APP = (app "linux").program;
        DOTFILES_TEST_SERVER_APP = (app "server").program;
      }
      ''
        python3 ${src}/tests/test_workflows.py
        touch "$out"
      '';

  # `nix flake check`: every .nix file is nixfmt-clean. The full system builds
  # stay local-only; CI runs this along with lint and the workflow regressions.
  fmtCheckFor =
    { system, src }:
    let
      pkgs = nixpkgs.legacyPackages.${system};
    in
    pkgs.runCommandLocal "dotfiles-fmt-check"
      {
        nativeBuildInputs = [ pkgs.nixfmt ];
      }
      ''
        cd ${src}
        nixfmt --check $(find . -name '*.nix' -type f)
        touch "$out"
      '';

  # `nix fmt`: run nixfmt over every .nix file (no extra flake input).
  fmtFor =
    system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
    in
    pkgs.writeShellApplication {
      name = "fmt";
      runtimeInputs = [
        pkgs.nixfmt
        pkgs.findutils
      ];
      text = ''
        if [ "$#" -eq 0 ]; then set -- .; fi
        find "$@" -name '*.nix' -type f -exec nixfmt {} +
      '';
    };
}
