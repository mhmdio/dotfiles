# Workstation-only packages — a machine someone sits in front of. GUI apps, the
# container VM, media tooling, and language runtimes. Imported by home/workstation.nix
# (a Linux desktop; the Mac mirrors this list in the Brewfile); home/server.nix does not,
# which is most of why the headless closure is small.
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # containers — colima runs the engine in a rootless VM (`colima start`). The
    # server runs a real distro engine and gets its client from there, so none
    # of this ships headless.
    docker # CLI + engine client
    docker-compose
    lazydocker
    colima

    # dev runtimes / build
    nodejs_24
    bun
    pnpm
    uv # Python runtime/installer; `uvx` runs one-off Python tools (MCP servers etc.)

    # media (transcode/convert helpers in config/shell/functions.zsh)
    ffmpeg
    imagemagick
    yt-dlp # video/audio downloader — YouTube + 1000s of sites (`yt-dlp <url>`)

    # cloud — credentials/profiles live in ~/.aws/config, never in this repo
    awscli2 # `aws` CLI — used directly by agents instead of an AWS MCP server
    cloudlens # k9s-like TUI for browsing AWS/GCP resources — `cloudlens`

    # interactive TUI apps
    posting # API client TUI — terminal Postman (`posting`)
    harlequin # SQL IDE for the terminal — `harlequin`
    bagels # expense tracker TUI — `bagels`
    hackernews-tui # Hacker News reader TUI (alias: hn)

    # GUI apps from nixpkgs
    _1password-cli # `op` CLI
    zed-editor # editor (CLI: zeditor)
  ];
}
