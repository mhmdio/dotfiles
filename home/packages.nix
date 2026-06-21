# Cross-platform CLI tools + runtimes (nixpkgs), shared by macOS + Linux.
# Client tools (kubectl, terraform, …) never here — those go in devenv.sh.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # core shell / file utils
    coreutils
    gawk
    gnupg
    curl
    wget
    rsync
    unzip
    p7zip

    # search / nav / viewers
    ripgrep
    fd
    fzf
    zoxide
    eza
    bat
    yazi

    # git (delta = diff pager)
    git
    git-lfs # large-file storage (filters wired in config/git/config)
    gh
    gh-dash # PR/issue dashboard; gh finds it on PATH as `gh dash` (alias: ghd)
    lazygit
    delta

    # nix helpers
    nix-output-monitor # nom: live build progress for `nix run .#mac` / `.#linux`
    nh # nicer rebuild/GC front-end (nom output + generation diff)
    nvd # generation diff — apply.sh shows what changed after a switch
    comma
    nix-index # `, <cmd>` runs any nixpkg uninstalled (run `nix-index` once)

    # dev runtimes / build (language runtimes live per-client in devenv.sh)
    gcc
    nodejs_24
    bun
    pnpm
    tree-sitter
    devenv # per-client reproducible shells (devenv.sh) + direnv

    # editor (tmux comes from programs.tmux — see home/tmux.nix)
    neovim

    # system / disk / containers
    btop
    dust
    duf
    gping
    lazydocker
    docker # CLI + engine client (`docker`, talks to the colima VM on macOS)
    docker-compose
    colima # rootless Linux VM backing docker on macOS — replaces Docker Desktop (`colima start`)

    # data / http / net
    jq
    yq-go
    httpie
    doggo
    rclone

    # power CLIs (sd=sed, hyperfine=bench, tealdeer=tldr)
    pandoc
    killport
    pwgen
    ast-grep
    scc
    starship
    sd
    hyperfine
    tealdeer

    # AI / agent
    opencode

    # fetch / pretty
    fastfetch
    glow
    gum

    # recording
    asciinema

    # media (transcode/convert helpers in functions.zsh)
    ffmpeg
    imagemagick

    # GUI apps from nixpkgs
    _1password-cli # `op` CLI
    wezterm # terminal
    zed-editor # editor (CLI: zeditor)
  ];
}
