# Flake helpers: host builders + lint/format derivations. Kept out of flake.nix
# so that file stays inputs + outputs wiring. Path arguments (hostModule,
# homeModule, src, modules) are passed in from the flake root so their relative
# references resolve there, not against this nix/ directory.
{ inputs }:
let
  inherit (inputs) nixpkgs nix-darwin home-manager;
in
{
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
        inherit system;
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

  # `nix fmt`: run nixfmt over every .nix file (no extra flake input).
  fmtFor =
    system:
    let
      pkgs = nixpkgs.legacyPackages.${system};
    in
    pkgs.writeShellApplication {
      name = "fmt";
      runtimeInputs = [
        pkgs.nixfmt-rfc-style
        pkgs.findutils
      ];
      text = ''
        if [ "$#" -eq 0 ]; then set -- .; fi
        find "$@" -name '*.nix' -type f -exec nixfmt {} +
      '';
    };
}
