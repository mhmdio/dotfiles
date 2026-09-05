# macOS-only home layer: imports the workstation profile + macOS GUI configs.
# The Linux homeConfigurations import that profile directly and never see this.
{ pkgs, lib, ... }:
let
  # Picks one wallpaper from the collection and sets it. Each file is a DYNAMIC
  # heic — two images plus an XMP apple_desktop:apr map of {l:0, d:1} (verified on
  # all six) — so macOS still swaps light/dark inside whichever one is showing.
  # That's why only the Mac "Dynamic" download is wired up: the separate
  # light/dark PNGs would each need their own switching logic to do the same job.
  wallpaper-shuffle = pkgs.writeShellApplication {
    name = "wallpaper-shuffle";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      # The store path is the whole point: its hash changes when the collection
      # does, and macOS caches wallpapers BY PATH, so a new generation is never
      # served a stale image (see also the parent-directory trick in git log).
      pick="$(find "${../wallpaper/mac}" -name '*.heic' -type f | shuf -n 1)"
      [ -n "$pick" ] || exit 0
      # || true: a switch must not fail because System Events is unapproved. The
      # first run raises an Automation permission prompt.
      /usr/bin/osascript -e "tell application \"System Events\" to tell every desktop to set picture to \"$pick\"" || true
    '';
  };
in
{
  imports = [ ./workstation.nix ];

  home.packages = [
    pkgs.mas # Mac App Store CLI
    wallpaper-shuffle # also runnable by hand to reroll the wallpaper
  ];

  # Karabiner never noticed a new generation: it watches the resolved path, and a
  # store symlink repoint is invisible to that. Measured — the target changed on
  # every switch since February and its log recorded no load in between, so edits
  # here only took effect on the next reboot. onChange fires when the FILE's
  # content differs (home-manager diffs source vs deployed, not store paths), and
  # the agent re-reads karabiner.json on start. || true so a switch never fails on
  # a keyboard remap.
  xdg.configFile."karabiner/karabiner.json" = {
    source = ./config/karabiner/karabiner.json;
    onChange = ''
      /bin/launchctl kickstart -k "gui/$UID/org.pqrs.service.agent.karabiner_console_user_server" || true
    '';
  };

  # Ghostty (cask, see hosts/mac.nix). A plain read-only symlink is fine here —
  # unlike lazygit, Ghostty only ever READS its config; reloading is
  # cmd+shift+, and it never writes the file back. Validate edits with
  # `ghostty +validate-config` before applying.
  xdg.configFile."ghostty/config".source = ./config/ghostty/config;

  # superfile (`spf`) — a Homebrew formula, not nixpkgs (reason in hosts/mac.nix),
  # so its config lives on the macOS-only layer alongside it.
  #
  # Symlinked file-by-file rather than as a whole directory on purpose: superfile
  # rewrites its bundled themes into ~/.config/superfile/theme/ whenever its
  # themeFileVersion changes, so that directory has to stay writable. Our theme is
  # called "terminal", a name no bundled theme uses, so it is never clobbered.
  # No XDG wiring needed — superfile resolves paths with adrg/xdg and
  # config/shell/envs.zsh already exports XDG_CONFIG_HOME.
  xdg.configFile."superfile/config.toml".source = ./config/superfile/config.toml;
  xdg.configFile."superfile/theme/terminal.toml".source = ./config/superfile/theme/terminal.toml;

  # Wallpaper: shuffled from wallpaper/mac on every switch, and hourly after that.
  # Both paths call the same script, so there is one definition of "pick one".
  home.activation.wallpaper = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${wallpaper-shuffle}/bin/wallpaper-shuffle || true
  '';
  launchd.agents.wallpaper-shuffle = {
    enable = true;
    config = {
      ProgramArguments = [ "${wallpaper-shuffle}/bin/wallpaper-shuffle" ];
      RunAtLoad = true; # reroll at login
      StartInterval = 3600; # and once an hour while logged in
    };
  };

  # Free ⌘Space for Raycast: disable Spotlight's hotkeys (search = 64, Finder
  # search window = 65). -dict-add edits only those keys, preserving every other
  # shortcut. Applies on next login. || true so a switch never fails on it.
  home.activation.disableSpotlightHotkeys = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 '<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>32</integer><integer>49</integer><integer>1048576</integer></array><key>type</key><string>standard</string></dict></dict>' || true
    run /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 65 '<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>32</integer><integer>49</integer><integer>1572864</integer></array><key>type</key><string>standard</string></dict></dict>' || true
  '';
}
