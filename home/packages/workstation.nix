# Workstation-only packages — a machine someone sits in front of. GUI apps, the
# container VM, media tooling, and language runtimes. Imported by home/workstation.nix
# (so both the Mac and a Linux desktop get it); home/server.nix deliberately does not,
# which is most of why the headless closure is small.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # containers — colima is the rootless Linux VM backing docker on macOS
    # (replaces Docker Desktop: `colima start`). The server runs a real distro
    # engine and gets its client from there, so none of this ships headless.
    docker # CLI + engine client (`docker`, talks to the colima VM on macOS)
    docker-compose
    lazydocker
    colima

    # dev runtimes / build (per-project versions still come from devenv.sh)
    nodejs_24
    bun
    pnpm
    devenv # per-client reproducible shells (devenv.sh) + direnv

    # media (transcode/convert helpers in config/shell/functions.zsh)
    ffmpeg
    imagemagick
    yt-dlp # video/audio downloader — YouTube + 1000s of sites (`yt-dlp <url>`)

    # interactive TUI apps
    posting # API client TUI — terminal Postman (`posting`)
    harlequin # SQL IDE for the terminal — `harlequin`
    bagels # expense tracker TUI — `bagels`
    hackernews-tui # Hacker News reader TUI (alias: hn)
    cloudlens # k9s-like TUI for browsing AWS/GCP resources — `cloudlens`

    # GUI apps from nixpkgs
    _1password-cli # `op` CLI
    wezterm # terminal
    zed-editor # editor (CLI: zeditor)
  ];
}
