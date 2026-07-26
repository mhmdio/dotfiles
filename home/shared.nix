# Portable user core (home-manager) — the floor every profile stands on:
# workstation.nix (Mac + Linux desktop) and server.nix (headless) both import it.
# Keep it GUI-free; desktop-only additions belong in the workstation layer.
# `username` comes from flake.nix so the repo is fork-and-go.
{
  config,
  pkgs,
  lib,
  username,
  inputs,
  ...
}:
{
  imports = [
    ./packages/core.nix
    ./dotfiles/core.nix
    ./tmux.nix
  ];

  # Pin `nixpkgs` to this flake's locked input, so `nix run nixpkgs#…` and comma
  # use the same version the system was built from.
  nix.registry.nixpkgs.flake = inputs.nixpkgs;

  # nix-darwin supplies these on macOS (mkDefault yields); Linux derives them.
  # root's home is /root, not /home/root, so a headless server run as root works.
  home.username = lib.mkDefault username;
  home.homeDirectory = lib.mkDefault (
    if pkgs.stdenv.hostPlatform.isDarwin then
      "/Users/${username}"
    else if username == "root" then
      "/root"
    else
      "/home/${username}"
  );
  home.stateVersion = "25.11";

  # git/theme are managed as raw dotfiles, not via programs.* (see dotfiles.nix).

  # gh: programs.gh owns ~/.config/gh/config.yml and installs gh-dash as a real
  # extension so `gh dash` (alias ghd) works — gh won't run gh-* PATH binaries.
  # Credential helper stays off; the raw git config already wires gh auth.
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = false;
    extensions = [ pkgs.gh-dash ];
    settings = {
      git_protocol = "https";
      editor = "nvim";
      prompt = "enabled";
      prefer_editor_prompt = "disabled";
      aliases.co = "pr checkout";
    };
  };

  # direnv: entry point for per-client devshells (devenv.sh).
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Quiet direnv's per-load "loading…" / "export +VAR…" status lines. Empty format
  # disables direnv's own logging; the devenv enterShell banner still prints.
  home.sessionVariables.DIRENV_LOG_FORMAT = "";

  # home-manager owns .zshrc/.zshenv; we export plugin store paths and source the
  # hand-written shell tree (config/shell) in its exact load order.
  programs.zsh = {
    enable = true;
    enableCompletion = false; # config/shell/inits runs compinit itself
    history = {
      path = "${config.home.homeDirectory}/.local/state/zsh/history";
      size = 100000;
      save = 100000;
    };
    initContent = ''
      export _NIX_FZF_SHELL_DIR="${pkgs.fzf}/share/fzf"
      export _NIX_FZF_TAB="${pkgs.zsh-fzf-tab}/share/fzf-tab/fzf-tab.plugin.zsh"
      export _NIX_ZSH_AUTOSUGGESTIONS="${pkgs.zsh-autosuggestions}/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
      export _NIX_ZSH_SYNTAX_HIGHLIGHTING="${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

      source "$HOME/.config/shell/all.zsh"
      [[ $- == *i* ]] && source "$HOME/.config/shell/zoptions.zsh"
    '';
  };

  xdg.configFile."shell".source = ./config/shell;

  programs.home-manager.enable = true;
}
