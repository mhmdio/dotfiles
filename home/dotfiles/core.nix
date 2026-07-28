# Portable dotfiles → read-only ~/.config symlinks. Every profile gets these,
# headless included; anything that configures a GUI app lives in
# dotfiles/workstation.nix. Paths are ../config/… — this file sits one level
# deeper than the config tree it points at.
# Theme: each tool autoswitches with the terminal itself (see its own config).
# gh-dash is the one exception — it can't, so it switches on OS appearance at
# launch instead; the `let` block below says why.
{ lib, pkgs, ... }:
let
  # gh-dash can't follow the terminal the way delta/fzf/btop do. It detects
  # light vs dark correctly, but every colour it draws is a hardcoded xterm
  # index emitted as truecolor, so the stock dashboard is xterm greys (#808080,
  # #c0c0c0) on a Catppuccin terminal — that's the "why is it grey".
  #
  # ANSI indices in the config don't help: gh-dash accepts them (dlvhdr/gh-dash#770)
  # but wraps every configured colour in a lipgloss compat.AdaptiveColor, whose
  # RGBA() flattens it to the *default* xterm RGB before it reaches the terminal.
  # Measured: primary "4" renders as #000080 navy, not Catppuccin blue.
  #
  # That wrapper also sets Light and Dark to the same value, so one config file
  # cannot cover both appearances. Hence two: same base, different theme block,
  # picked at launch by the `ghd` function in shell/aliases.zsh.
  ghDashConfig =
    flavour:
    pkgs.writeText "gh-dash-${flavour}.yml" (
      builtins.readFile ../config/gh-dash/config.yml
      + builtins.readFile (../config/gh-dash + "/theme-${flavour}.yml")
    );
  ghDashMocha = ghDashConfig "mocha";
in
{
  xdg.configFile = {
    # whole-dir tools (tmux is managed via programs.tmux — see home/tmux.nix)
    "yazi".source = ../config/yazi;
    "git".source = ../config/git;

    # gh/config.yml is managed by programs.gh (see shared.nix), not symlinked here.
    # gh-dash is a gh extension (also shared.nix) but keeps its own config, which
    # was never declared — a fresh machine got the stock dashboard. Safe to
    # symlink read-only: gh-dash only ever writes this file when it's missing
    # (createConfigFileIfMissing), never on migration the way lazygit does.
    # config.yml is the mocha build so a bare `gh dash` still works; `ghd` picks.
    "gh-dash/config.yml".source = ghDashMocha;
    "gh-dash/config-mocha.yml".source = ghDashMocha;
    "gh-dash/config-latte.yml".source = ghDashConfig "latte";

    # opencode: only the AGENTS.md guidelines (auth.json / opencode.json stay writable)
    "opencode/AGENTS.md".source = ../config/opencode/AGENTS.md;

    # lazygit: not symlinked — it rewrites config.yml on schema migrations;
    # installed as a writable copy below (see lazygitConfig activation).

    # granular so ~/.config/nvim stays writable for lazy-lock.json
    "nvim/init.lua".source = ../config/nvim/init.lua;
    "nvim/lua".source = ../config/nvim/lua;
    "nvim/lazyvim.json".source = ../config/nvim/lazyvim.json;
    "nvim/stylua.toml".source = ../config/nvim/stylua.toml;
    "nvim/.neoconf.json".source = ../config/nvim/.neoconf.json;

    "starship.toml".source = ../config/starship.toml;

    # fzf default options (FZF_DEFAULT_OPTS_FILE → ~/.config/fzf/fzfrc).
    "fzf/fzfrc".source = ../config/fzf/fzfrc;
  }
  # bat/btop: raw configs on macOS (theme auto-switches with the OS). On Linux
  # they're home-manager program modules painted by catppuccin (see
  # home/theme-mocha.nix), so symlinking the raw config here too would collide —
  # keep it Darwin-only.
  // lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
    # btop: built-in "TTY" theme (terminal ANSI colors) — no theme files.
    "btop/btop.conf".source = ../config/btop/btop.conf;
    # bat ships Catppuccin built in — config selects per terminal background.
    "bat/config".source = ../config/bat/config;
  };

  # lazygit rewrites config.yml on schema migrations, so install a writable copy
  # (not a read-only store symlink). Repo stays source of truth; re-applied each
  # switch.
  home.activation.lazygitConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "$HOME/.config/lazygit"
    run rm -f "$HOME/.config/lazygit/config.yml"
    run install -m 0644 ${../config/lazygit/config.yml} "$HOME/.config/lazygit/config.yml"
  '';
}
