{ pkgs, username, ... }:
{
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true; # 1Password CLI, etc.
  system.stateVersion = 6;

  system.primaryUser = username;
  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
  };

  # Lix owns Nix; don't let nix-darwin manage /etc/nix or the daemon.
  nix.enable = false;

  # Touch ID for sudo. macOS 26 already ships `auth include sudo_local` in
  # /etc/pam.d/sudo, so nix-darwin only drops the file in — no patching of Apple's
  # file, and nothing unmanaged in the way. `reattach` is what makes it usable
  # here: without pam_reattach, Touch ID never prompts inside a multiplexed or
  # screen-sharing session. Config changes don't need any of this — they
  # go through `make home`, which never touches root.
  security.pam.services.sudo_local = {
    enable = true;
    touchIdAuth = true;
    reattach = true;
  };

  # ...and no prompt at all for the one command `apply.sh` escalates. Scoped to
  # darwin-rebuild rather than a blanket rule, but be clear about what it buys:
  # `darwin-rebuild switch --flake <anything>` runs arbitrary activation code as
  # root, so this makes anything that can run as this user root-equivalent, and
  # the dotfiles repo a credential worth protecting. apply.sh skips its `sudo -v`
  # priming when this rule is live (`sudo -n -l darwin-rebuild`), since -v
  # validates for ALL commands and would prompt regardless.
  security.sudo.extraConfig = ''
    ${username} ALL=(root) NOPASSWD: /run/current-system/sw/bin/darwin-rebuild
  '';

  # System zsh wires Nix paths into every login shell via /etc/zshrc. The three
  # opt-outs remove work that /etc/zshrc did before ~/.zshrc even started, all of
  # it either duplicated or immediately overwritten downstream.
  programs.zsh = {
    enable = true;
    # config/shell/inits.zsh runs the one compinit, after it has finished
    # extending fpath — a second one here just doubled the work.
    enableGlobalCompInit = false;
    enableBashCompletion = false; # nothing here ships bash-only completions
    promptInit = ""; # starship is the prompt; this set `prompt suse` first
  };

  fonts.packages = with pkgs; [
    maple-mono.NF
    nerd-fonts.hack
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
  ];

  system.defaults = {
    dock = {
      autohide = true;
      orientation = "right";
      tilesize = 48;
      persistent-apps = [
        # pinned dock apps, first → last (top → bottom, since the dock is on the right)
        "/Applications/Ghostty.app"
        "/Applications/Obsidian.app"
        "/Applications/Google Chrome.app"
        "/Applications/Slack.app"
      ];
      persistent-others = [ ]; # no pinned folders/files
      show-recents = false; # drop the recent-apps section
      mru-spaces = false; # don't auto-rearrange Spaces by recent use
      autohide-delay = 0.0; # reveal instantly on hover
      autohide-time-modifier = 0.4;
      launchanim = false;
      mineffect = "scale";
      show-process-indicators = true;
    };
    finder = {
      ShowPathbar = true;
      ShowStatusBar = true;
      AppleShowAllExtensions = true;
      FXEnableExtensionChangeWarning = false;
      _FXShowPosixPathInTitle = true;
      FXPreferredViewStyle = "Nlsv"; # list view
      _FXSortFoldersFirst = true;
      FXDefaultSearchScope = "SCcf"; # search the current folder
    };
    WindowManager = {
      StandardHideWidgets = true; # no widgets on the desktop
      EnableTilingByEdgeDrag = false; # don't tile when dragging to edges
      EnableTopTilingByEdgeDrag = false; # don't fill when dragging to menu bar
    };
    # NOTE: universalaccess.reduceMotion is SIP-protected — `defaults write` it
    # during activation fails ("Could not write domain") and aborts the switch.
    # Reduce Motion is off by default; toggle it by hand if ever needed.
    NSGlobalDomain = {
      _HIHideMenuBar = true; # auto-hide the menu bar
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
      "com.apple.swipescrolldirection" = false; # traditional scroll (down = down)
      AppleShowAllExtensions = true;
      ApplePressAndHoldEnabled = false; # hold a key to repeat, not the accent popup
      NSAutomaticCapitalizationEnabled = false;
      NSAutomaticDashSubstitutionEnabled = false;
      NSAutomaticPeriodSubstitutionEnabled = false;
      NSAutomaticQuoteSubstitutionEnabled = false; # no smart quotes (code-friendly)
      NSAutomaticSpellingCorrectionEnabled = false;
      NSNavPanelExpandedStateForSaveMode = true; # expanded save dialogs
      PMPrintingExpandedStateForPrint = true;
    };
    trackpad = {
      Clicking = true; # tap to click
      TrackpadThreeFingerDrag = true;
    };
    screencapture = {
      type = "png";
      disable-shadow = true;
    };
    loginwindow.GuestEnabled = false;
    LaunchServices.LSQuarantine = false; # no "are you sure you want to open" nag
    # Toggles nix-darwin has no named option for (written to com.apple.dock).
    CustomUserPreferences."com.apple.dock" = {
      "workspaces-auto-swoosh" = false; # don't jump to a Space on app activate
      "mcx-expose-disabled" = true; # no Mission Control on drag-to-top
    };
  };

  # Homebrew = GUI .app casks, plus the rare CLI nixpkgs can't ship current enough
  # (see `brews` — each one needs a stated reason). nix-darwin drives `brew bundle`;
  # the zap-prune below removes anything NOT listed here, formulae included, so a
  # `brew install` you don't declare disappears on the next switch. Nothing is
  # auto-upgraded on switch (see onActivation) — bump deliberately with
  # `brew upgrade [--cask] <name>`, or `b up`.
  homebrew = {
    enable = true;
    onActivation = {
      # zap-prune: remove any cask not in the list below and clear its app data.
      # (nix-darwin emits `--zap --force-cleanup` for this — verified at the pinned rev.)
      cleanup = "zap";
      # Both default false for idempotency — leave them off so a switch never refreshes
      # brew or upgrades casks behind your back (an unasked-for upgrade once broke a
      # mid-activation docker-desktop bump). Refresh casks deliberately, not on switch.
      autoUpdate = false;
      upgrade = false;
    };

    # CLI formulae — the documented exception to "every CLI comes from nixpkgs".
    # Re-check these on flake bumps; when nixpkgs catches up, move them to
    # home/packages/ and drop the entry.
    brews = [
      # `spf` — TUI file manager. nixpkgs is stuck on 1.3.3; brew ships 1.6.0, and
      # home/config/superfile targets the newer config schema. Config is symlinked
      # from home/darwin.nix.
      "superfile"
    ];

    casks = [
      "ghostty" # terminal — auto_updates, so brew won't fight its self-updater
      "karabiner-elements"
      "1password"
      "hiddenbar"
      "shottr"
      "transmission"
      "google-chrome"
      "raycast"
      "obsidian"
      "dropbox"
      "keepingyouawake"
      "tailscale-app"
      "claude"
      "codex" # CLI, but cask-only upstream — self-updates like claude (see core.nix)
      "agentsview"
      "google-drive"
      "iina"
      "slack"
      "twingate"
    ];
  };
}
