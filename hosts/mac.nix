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

  # touch-id sudo unmanaged: the sudo_local symlink needs root context SIP denies
  # in some activation paths. Enable touchIdAuth + apply via interactive sudo to add.
  security.pam.services.sudo_local.enable = false;

  # System zsh wires Nix paths into every login shell via /etc/zshrc.
  programs.zsh.enable = true;

  fonts.packages = with pkgs; [
    maple-mono.NF
    nerd-fonts.fira-code
    nerd-fonts.hack
    nerd-fonts.jetbrains-mono
  ];

  system.defaults = {
    dock = {
      autohide = true;
      orientation = "right";
      tilesize = 48;
      persistent-apps = [
        # pinned dock apps, left → right
        "/System/Applications/Mail.app"
        "/System/Applications/Calendar.app"
        "/Users/${username}/Applications/Home Manager Apps/WezTerm.app"
        "/Users/${username}/Applications/Home Manager Apps/Zed.app"
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

  # Homebrew = GUI .app casks only; every CLI comes from nixpkgs. nix-darwin drives
  # `brew bundle`; the zap-prune below removes any cask not in this list (declarative),
  # and each `nix run .#mac` refreshes + upgrades casks. Heads-up: a cask you installed
  # by hand and didn't add here will be removed on the next switch.
  homebrew = {
    enable = true;
    onActivation = {
      # cleanup="zap" would emit brew's deprecated `--cleanup` switch (Homebrew 6.x).
      # Reproduce the same forced zap-prune with brew's current flags via extraFlags:
      # --force-cleanup performs+forces the prune, --zap also clears each cask's data.
      cleanup = "none";
      autoUpdate = true;
      upgrade = true;
      extraFlags = [ "--zap" "--force-cleanup" ];
    };

    casks = [
      "karabiner-elements"
      "1password"
      "hiddenbar"
      "netnewswire"
      "shottr"
      "telegram"
      "transmission"
      "google-chrome"
      "raycast"
      "obsidian"
      "discord"
      "whatsapp"
      "zoom"
      "dropbox"
      "keepingyouawake"
      "tailscale-app"
      "claude"
      "agentsview"
      "google-drive"
      "iina"
      "slack"
    ];
  };
}
