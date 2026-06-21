# Cross-platform dotfiles → read-only ~/.config symlinks.
# Theme: each tool autoswitches with the terminal itself (see its own config).
{ lib, pkgs, ... }:
{
  xdg.configFile = {
    # whole-dir tools (tmux is managed via programs.tmux — see home/tmux.nix)
    "wezterm".source = ./config/wezterm;
    "yazi".source = ./config/yazi;
    "git".source = ./config/git;

    # single file (skip secret/state siblings)
    "gh/config.yml".source = ./config/gh/config.yml;

    # opencode: only the AGENTS.md guidelines (auth.json / opencode.json stay writable)
    "opencode/AGENTS.md".source = ./config/opencode/AGENTS.md;

    # lazygit: not symlinked — it rewrites config.yml on schema migrations;
    # installed as a writable copy below (see lazygitConfig activation).

    # granular so ~/.config/nvim stays writable for lazy-lock.json
    "nvim/init.lua".source = ./config/nvim/init.lua;
    "nvim/lua".source = ./config/nvim/lua;
    "nvim/lazyvim.json".source = ./config/nvim/lazyvim.json;
    "nvim/stylua.toml".source = ./config/nvim/stylua.toml;
    "nvim/.neoconf.json".source = ./config/nvim/.neoconf.json;

    # Zed: not symlinked — it rewrites these in-app; see zedConfig activation below.

    "starship.toml".source = ./config/starship.toml;

    # fzf default options (FZF_DEFAULT_OPTS_FILE → ~/.config/fzf/fzfrc).
    "fzf/fzfrc".source = ./config/fzf/fzfrc;
  }
  # bat/btop: raw configs on macOS (theme auto-switches with the OS). On Linux
  # they're home-manager program modules painted by catppuccin (see home/linux.nix),
  # so symlinking the raw config here too would collide — keep it Darwin-only.
  // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
    # btop: built-in "TTY" theme (terminal ANSI colors) — no theme files.
    "btop/btop.conf".source = ./config/btop/btop.conf;
    # bat ships Catppuccin built in — config selects per terminal background.
    "bat/config".source = ./config/bat/config;
  };

  # Zed rewrites its config in-app, so install writable copies (not read-only
  # store symlinks). Repo stays source of truth; re-applied each switch.
  home.activation.zedConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "$HOME/.config/zed"
    run rm -f "$HOME/.config/zed/settings.json" "$HOME/.config/zed/keymap.json"
    run install -m 0644 ${./config/zed/settings.json} "$HOME/.config/zed/settings.json"
    run install -m 0644 ${./config/zed/keymap.json}   "$HOME/.config/zed/keymap.json"
  '';

  # lazygit rewrites config.yml on schema migrations — same writable-copy fix.
  home.activation.lazygitConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "$HOME/.config/lazygit"
    run rm -f "$HOME/.config/lazygit/config.yml"
    run install -m 0644 ${./config/lazygit/config.yml} "$HOME/.config/lazygit/config.yml"
  '';
}
