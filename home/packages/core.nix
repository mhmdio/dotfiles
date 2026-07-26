# Portable CLI core (nixpkgs) — every profile gets this: macOS, Linux desktop,
# and the headless server. Nothing here assumes a GUI, a display server, or a
# container runtime; anything that does lives in packages/workstation.nix.
# Client tools (kubectl, terraform, …) never here — those go in devenv.sh.
{ pkgs, lib, ... }:
{
  home.packages =
    with pkgs;
    [
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
      yazi

      # git (delta = diff pager; gh + gh-dash come from programs.gh — see shared.nix)
      git
      git-lfs # large-file storage (filters wired in config/git/config)
      lazygit
      lazyworktree # git worktree manager TUI (alias: lwt)
      delta

      # nix helpers
      nix-output-monitor # nom: live build progress for `nix run .#mac` / `.#linux`
      nh # nicer rebuild/GC front-end (nom output + generation diff)
      nvd # generation diff — apply.sh shows what changed after a switch
      comma
      nix-index # `, <cmd>` runs any nixpkg uninstalled (run `nix-index` once)

      # build toolchain (language runtimes are workstation-only — see workstation.nix)
      gcc
      tree-sitter

      # editor (tmux comes from programs.tmux — see home/tmux.nix)
      neovim

      # system / disk
      dust
      duf
      gping

      # data / http / net
      jq
      jnv # interactive jq TUI — build & preview jq filters live (replaces raw jq)
      fx # interactive JSON viewer — browse/fold/query JSON in a TUI (replaces jq/less)
      yq-go
      httpie
      xh # fast curl/httpie alternative — simpler syntax, HTTP/2
      doggo
      trippy # `trip` — interactive traceroute (replaces ping/traceroute)
      bandwhich # live per-process network usage (replaces iftop/nethogs)
      rclone

      # power CLIs (sd=sed, hyperfine=bench, tealdeer=tldr, choose=cut/awk)
      pandoc
      killport
      pwgen
      ast-grep
      scc
      starship
      atuin # SQLite shell history on Ctrl-R — stats, exit codes, optional sync
      sd
      choose # field selection by index (replaces cut/awk) — e.g. `choose 1`
      viddy # modern `watch` — time-travel, diffs, history
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
    ]
    # bat/btop: raw packages here on macOS (raw configs in dotfiles/core.nix); on
    # Linux they come via programs.bat/btop instead so catppuccin themes them
    # (home/theme-mocha.nix) — that applies to the desktop and the server alike.
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      bat
      btop
    ];
}
