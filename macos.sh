#!/usr/bin/env bash
# ============================================================================
# macOS preferences — what nix-darwin's `system.defaults` used to apply. They
# live in preference plists and persist on their own, so this only needs to run
# on a fresh Mac or after changing a value here. Some take effect at next login.
#
#   ./macos.sh
# ============================================================================
set -euo pipefail
[ "$(uname -s)" = Darwin ] || { echo "macos.sh is macOS-only" >&2; exit 1; }

dw() { defaults write "$@"; }

# ── Dock (right edge, autohide, no recents) ─────────────────────────────────
dw com.apple.dock autohide -bool true
dw com.apple.dock orientation -string right
dw com.apple.dock tilesize -int 48
dw com.apple.dock show-recents -bool false
dw com.apple.dock mru-spaces -bool false # don't reorder Spaces by recent use
dw com.apple.dock autohide-delay -float 0
dw com.apple.dock autohide-time-modifier -float 0.4
dw com.apple.dock launchanim -bool false
dw com.apple.dock mineffect -string scale
dw com.apple.dock show-process-indicators -bool true
dw com.apple.dock workspaces-auto-swoosh -bool false # don't jump Spaces on app activate
dw com.apple.dock mcx-expose-disabled -bool true # no Mission Control on drag-to-top
# Pinned apps, top → bottom (the dock is on the right). No pinned folders.
dw com.apple.dock persistent-others -array
dw com.apple.dock persistent-apps -array
for app in "Ghostty" "Obsidian" "Google Chrome" "Slack"; do
  dw com.apple.dock persistent-apps -array-add \
    "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>file:///Applications/${app// /%20}.app/</string><key>_CFURLStringType</key><integer>15</integer></dict></dict></dict>"
done

# ── Finder ──────────────────────────────────────────────────────────────────
dw com.apple.finder ShowPathbar -bool true
dw com.apple.finder ShowStatusBar -bool true
dw com.apple.finder AppleShowAllExtensions -bool true
dw com.apple.finder FXEnableExtensionChangeWarning -bool false
dw com.apple.finder _FXShowPosixPathInTitle -bool true
dw com.apple.finder FXPreferredViewStyle -string Nlsv # list view
dw com.apple.finder _FXSortFoldersFirst -bool true
dw com.apple.finder FXDefaultSearchScope -string SCcf # search the current folder

# ── Window manager ──────────────────────────────────────────────────────────
dw com.apple.WindowManager StandardHideWidgets -bool true
dw com.apple.WindowManager EnableTilingByEdgeDrag -bool false
dw com.apple.WindowManager EnableTopTilingByEdgeDrag -bool false

# ── Global ──────────────────────────────────────────────────────────────────
dw NSGlobalDomain _HIHideMenuBar -bool true # auto-hide the menu bar
dw NSGlobalDomain InitialKeyRepeat -int 15
dw NSGlobalDomain KeyRepeat -int 2
dw NSGlobalDomain com.apple.swipescrolldirection -bool false # traditional scroll
dw NSGlobalDomain AppleShowAllExtensions -bool true
dw NSGlobalDomain ApplePressAndHoldEnabled -bool false # key repeat, not accent popup
dw NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
dw NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
dw NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
dw NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
dw NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false
dw NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
dw NSGlobalDomain PMPrintingExpandedStateForPrint -bool true

# ── Trackpad: tap to click, three-finger drag ───────────────────────────────
for domain in com.apple.AppleMultitouchTrackpad com.apple.driver.AppleBluetoothMultitouch.trackpad; do
  dw "$domain" Clicking -bool true
  dw "$domain" TrackpadThreeFingerDrag -bool true
done

# ── Screenshots ─────────────────────────────────────────────────────────────
dw com.apple.screencapture type -string png
dw com.apple.screencapture disable-shadow -bool true

# ── Gatekeeper's "are you sure you want to open" nag ────────────────────────
dw com.apple.LaunchServices LSQuarantine -bool false

# ── Free ⌘Space for Raycast: disable Spotlight's hotkeys (64 = search,
#    65 = Finder search window). -dict-add leaves every other shortcut alone.
dw com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 64 '<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>32</integer><integer>49</integer><integer>1048576</integer></array><key>type</key><string>standard</string></dict></dict>'
dw com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 65 '<dict><key>enabled</key><false/><key>value</key><dict><key>parameters</key><array><integer>32</integer><integer>49</integer><integer>1572864</integer></array><key>type</key><string>standard</string></dict></dict>'

killall Dock Finder SystemUIServer >/dev/null 2>&1 || true

# Root-owned, so not run here — once, by hand, on a fresh Mac:
#   sudo defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool false
# Touch ID for sudo (pam-reattach is in the Brewfile; works inside tmux too):
#   printf 'auth       optional       /opt/homebrew/lib/pam/pam_reattach.so ignore_ssh\nauth       sufficient     pam_tid.so\n' | sudo tee /etc/pam.d/sudo_local
echo "macOS defaults applied — some take effect after logout."
