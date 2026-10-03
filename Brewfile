# Everything this Mac installs. Homebrew replaced nix-darwin + home-manager.
#
#   brew bundle                 install anything missing (never upgrades by itself)
#   brew bundle check           is the machine missing anything declared here?
#   brew bundle cleanup         list what's installed but NOT declared (add --force to remove)
#
# Configs live in home/config and are symlinked into ~/.config by ./install.sh.

tap "abue-ammar/tinycast"

# ── core shell / file utils ─────────────────────────────────────────────────
brew "coreutils" # GNU ls/cat/date… — gnubin goes first on PATH (shell/path.zsh)
brew "gawk"
brew "gnupg"
brew "wget"
brew "rsync" # real rsync 3.x; macOS ships openrsync
brew "p7zip" # 7z / 7za

# ── search / nav / viewers ──────────────────────────────────────────────────
brew "ripgrep"
brew "fd"
brew "fzf"
brew "zoxide"
brew "eza"
brew "bat"
brew "superfile" # `spf` — TUI file manager

# ── git ─────────────────────────────────────────────────────────────────────
brew "git"
brew "git-lfs"
brew "git-delta" # diff pager
brew "lazygit"
brew "gh" # + `gh extension install dlvhdr/gh-dash` (install.sh does it)
brew "worktrunk"

# ── editor (LazyVim) ────────────────────────────────────────────────────────
# C compiler for treesitter parsers comes from the Xcode Command Line Tools.
brew "neovim"
brew "tree-sitter-cli"

# ── shell ───────────────────────────────────────────────────────────────────
brew "starship"
brew "atuin" # SQLite shell history on Ctrl-R
brew "direnv"
brew "zsh-autosuggestions"
brew "zsh-syntax-highlighting"
brew "fzf-tab"

# ── system / disk ───────────────────────────────────────────────────────────
brew "btop"
brew "dust"
brew "duf"
brew "gping"
brew "fastfetch"

# ── data / http / net ───────────────────────────────────────────────────────
brew "jq"
brew "jnv" # interactive jq
brew "fx" # interactive JSON viewer
brew "yq"
brew "httpie"
brew "xh"
brew "doggo"
brew "trippy" # `trip`
brew "bandwhich"
brew "rclone"

# ── power CLIs ──────────────────────────────────────────────────────────────
brew "pandoc"
brew "killport"
brew "pwgen"
brew "ast-grep"
brew "scc"
brew "sd"
brew "choose-rust" # `choose`
brew "viddy"
brew "hyperfine"
brew "tealdeer" # `tldr`
brew "glow"
brew "gum"
brew "asciinema"
brew "tuios"

# ── secrets ─────────────────────────────────────────────────────────────────
brew "age"
brew "sops"
cask "1password-cli" # `op`

# ── containers (colima = the Linux VM behind `docker`) ──────────────────────
brew "colima"
brew "docker"
brew "docker-buildx" # plugins need ~/.docker/config.json → cliPluginsExtraDirs (install.sh)
brew "docker-compose"
brew "docker-credential-helper" # docker-credential-osxkeychain, for credsStore
brew "lazydocker"

# ── runtimes ────────────────────────────────────────────────────────────────
brew "node"
brew "bun"
brew "pnpm"
brew "uv" # Python; `uvx` for one-off tools

# ── media ───────────────────────────────────────────────────────────────────
brew "ffmpeg"
brew "imagemagick"
brew "yt-dlp"

# ── cloud ───────────────────────────────────────────────────────────────────
brew "awscli"

# ── TUI apps ────────────────────────────────────────────────────────────────
brew "posting" # API client
brew "harlequin" # SQL IDE
brew "bagels" # expense tracker

# ── macOS ───────────────────────────────────────────────────────────────────
brew "mas" # Mac App Store CLI
brew "pam-reattach" # lets Touch ID sudo work inside tmux / screen sharing

# ── fonts ───────────────────────────────────────────────────────────────────
cask "font-maple-mono-nf"
cask "font-hack-nerd-font"

# ── apps ────────────────────────────────────────────────────────────────────
cask "1password"
cask "agentsview"
cask "claude"
cask "codex"
cask "dropbox"
cask "ghostty"
cask "google-chrome"
cask "google-drive"
cask "hiddenbar"
cask "iina"
cask "karabiner-elements"
cask "keepingyouawake"
cask "obsidian"
cask "omniwm"
cask "raycast"
cask "shottr"
cask "slack"
cask "tailscale-app"
cask "tinycast"
cask "transmission"
cask "twingate"
cask "zed"
