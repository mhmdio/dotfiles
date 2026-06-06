# macOS-only home layer: imports the shared core + macOS GUI configs.
# The Linux homeConfiguration uses shared.nix directly and never sees this.
{ pkgs, lib, ... }:
{
  imports = [ ./shared.nix ];

  home.packages = [ pkgs.mas ]; # Mac App Store CLI

  xdg.configFile."karabiner/karabiner.json".source = ./config/karabiner/karabiner.json;

  # Wallpaper: dynamic .heic (Latte/Mocha) macOS switches with the appearance. Point
  # at the file via its store DIRECTORY: the changing hash sits on the parent path so
  # macOS reloads instead of caching, while the name it shows stays a clean
  # "catppuccin" (not the hash). First run may prompt to allow System Events.
  home.activation.wallpaper = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run /usr/bin/osascript -e 'tell application "System Events" to tell every desktop to set picture to "${./assets}/catppuccin.heic"' || true
  '';

  # Free ⌘Space for Raycast: disable Spotlight's hotkeys (search = 64, Finder
  # search window = 65). -dict-add edits only those keys, preserving every other
  # shortcut. Applies on next login. || true so a switch never fails on it.
  home.activation.disableSpotlightHotkeys = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 '<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>32</integer><integer>49</integer><integer>1048576</integer></array><key>type</key><string>standard</string></dict></dict>' || true
    run /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 65 '<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>32</integer><integer>49</integer><integer>1572864</integer></array><key>type</key><string>standard</string></dict></dict>' || true
  '';
}
