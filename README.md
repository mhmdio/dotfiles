<div align="center">

# dotfiles

**A declarative, reproducible dev machine — one command, macOS or Linux.**

[![Nix flake](https://img.shields.io/badge/Nix-flake-5277C3?logo=nixos&logoColor=white)](https://nixos.org)
[![Lix](https://img.shields.io/badge/Lix-Nix-0c7dbe?logo=nixos&logoColor=white)](https://lix.systems)
[![nix-darwin](https://img.shields.io/badge/nix--darwin-unstable-5277C3?logo=apple&logoColor=white)](https://github.com/nix-darwin/nix-darwin)
[![home-manager](https://img.shields.io/badge/home--manager-unstable-5277C3?logo=gnubash&logoColor=white)](https://github.com/nix-community/home-manager)
[![platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-555?logo=linux&logoColor=white)](#bootstrap)
[![client tools](https://img.shields.io/badge/client%20tools-devenv.sh-8839ef?logo=nixos&logoColor=white)](https://devenv.sh)

</div>

## Demo

![A short showcase of the themed terminal — fastfetch, eza tree, bat](.github/demo.gif)

> Recorded with [vhs](https://github.com/charmbracelet/vhs); regenerate with `nix run .#demo`.

## Architecture

Each layer **depends on the layer below it**. macOS gets the full stack; Linux
takes the same Nix → home-manager path and simply skips the macOS-only layer.
A headless box stops one layer earlier still — see [Profiles](#profiles) below.

```mermaid
flowchart BT
    HW["`**Your machine**
    macOS · Linux (non-NixOS)`"]
    NIX["`**Lix · Nix**
    interpreter + daemon + store
    flake on nixpkgs-unstable`"]
    DAR["`**nix-darwin** — macOS only
    system defaults · fonts · Homebrew casks
    hosts/mac.nix`"]
    HM["`**home-manager**
    CLI tools · runtimes · zsh · dotfiles
    home/`"]
    DEV["`**devenv.sh** — per client
    kubectl · terraform · awscli …
    via direnv, in each client repo`"]

    HW  -->|"installs"| NIX
    NIX -->|"macOS"| DAR
    DAR --> HM
    NIX -.->|"Linux · standalone"| HM
    HM  -->|"per project"| DEV

    classDef base   fill:#eff1f5,stroke:#6c6f85,stroke-width:2px,color:#4c4f69;
    classDef nix    fill:#dce0fb,stroke:#1e66f5,stroke-width:3px,color:#1e66f5;
    classDef darwin fill:#fde9dc,stroke:#fe640b,stroke-width:3px,color:#fe640b;
    classDef home   fill:#f0e2fd,stroke:#8839ef,stroke-width:3px,color:#8839ef;
    classDef devenv fill:#e0f2db,stroke:#40a02b,stroke-width:3px,color:#40a02b,stroke-dasharray:5 5;

    class HW base;
    class NIX nix;
    class DAR darwin;
    class HM home;
    class DEV devenv;

    linkStyle 0,1,2,4 stroke:#9ca0b0,stroke-width:2px;
    linkStyle 3 stroke:#40a02b,stroke-width:2px,stroke-dasharray:6 4;
```

### Profiles

The home-manager layer is **three entry points over one shared core**, so the
same shell, keybinds and dotfiles land on a laptop and on a server the size of a
CAX11. Where you add a package decides how far it travels:

```mermaid
flowchart LR
    SH["`**shared.nix**
    portable core — zsh · git · CLIs
    packages/core.nix · dotfiles/core.nix`"]
    WS["`**workstation.nix**
    + desktop layer
    packages/workstation.nix · dotfiles/workstation.nix`"]
    MAC["`**darwin.nix** — macOS
    GUI configs · wallpaper`"]
    LIN["`**linux.nix** — Linux desktop
    + Catppuccin Mocha`"]
    SRV["`**server.nix** — headless
    + Mocha · lazydocker`"]

    SH  --> WS
    WS  --> MAC
    WS  --> LIN
    SH  -.-> SRV

    classDef core   fill:#dce0fb,stroke:#1e66f5,stroke-width:3px,color:#1e66f5;
    classDef desk   fill:#f0e2fd,stroke:#8839ef,stroke-width:3px,color:#8839ef;
    classDef leaf   fill:#eff1f5,stroke:#6c6f85,stroke-width:2px,color:#4c4f69;
    classDef server fill:#e0f2db,stroke:#40a02b,stroke-width:3px,color:#40a02b;

    class SH core;
    class WS desk;
    class MAC,LIN leaf;
    class SRV server;

    linkStyle 0,1,2 stroke:#9ca0b0,stroke-width:2px;
    linkStyle 3 stroke:#40a02b,stroke-width:2px,stroke-dasharray:6 4;
```

| Profile | Apply with | Flake output |
|---|---|---|
| `home/darwin.nix` | `nix run .#mac` | `darwinConfigurations.mac` |
| `home/linux.nix` | `nix run .#linux` | `homeConfigurations.<you>` · `<you>-aarch64` |
| `home/server.nix` | `nix run .#server` | `homeConfigurations.<serverUser>-server` · `-aarch64` |

The headless profile importing `shared.nix` **directly** is the whole
distinction — no WezTerm/Zed/1Password, no colima VM, no node/bun/pnpm, no media
toolchain. Adding a tool to `packages/workstation.nix` therefore never grows the
server closure; you opt in from `server.nix`, on purpose. Both Linux profiles are
built for `x86_64` and `aarch64`, so a Hetzner box works whichever it is.

<details>
<summary><h2>Features</h2></summary>

- **One command, reproducible** — `bootstrap.sh` brings up the whole machine; idempotent and safe to re-run.
- **Cross-platform, one config** — identical CLI environment on macOS, non-NixOS Linux, and headless servers; each profile just stops at a different layer.
- **Nix-first** — every CLI and runtime from nixpkgs (unstable, latest versions); Homebrew only for GUI `.app`s nixpkgs lacks.
- **Dotfiles as code** — `~/.config/*` are read-only symlinks from the repo (nvim & Zed kept granular so they keep their own state; WezTerm is copied rather than linked, so its own config watcher still fires).
- **Theme follows the OS** — Catppuccin Mocha (dark) / Latte (light); no switcher, no rebuild.
- **One-line tool changes** — add or remove a name in a single file, then re-apply.
- **Forkable** — the account is auto-detected; just swap the cask list and it's yours.
- **Client tools stay out** — kubectl/terraform/awscli live per-client in [devenv.sh](https://devenv.sh), never here.

</details>

<details>
<summary><h2>Why this — vs chezmoi · stow · mise</h2></summary>

Most dotfile tools manage **one slice** of a machine. This repo manages the whole
thing — dotfiles **and** CLIs **and** runtimes **and** macOS defaults **and** GUI
casks **and** fonts — from one declarative source, applied with one `switch`.

| Approach | Manages | Pins exact versions | Atomic + rollback | One config, macOS + Linux |
|---|---|---|---|---|
| **This repo** — Nix flake · home-manager · nix-darwin | dotfiles · CLIs · runtimes · macOS defaults · casks · fonts | ✅ `flake.lock` (whole closure) | ✅ generations | ✅ |
| **Plain dotfiles + Brewfile** | dotfiles (hand-rolled symlinks) · brew pkgs | ⚠️ "latest at install" | ❌ | ⚠️ manual branches |
| **GNU Stow** | dotfile symlinks only | ❌ no packages | ❌ | ⚠️ symlinks only |
| **chezmoi** | dotfiles (+ templates, secrets) | ❌ installs via imperative hooks | ❌ | ⚠️ dotfiles only |
| **mise / asdf** | per-project runtimes + tasks | ✅ per project, not the OS | ❌ | ⚠️ runtimes only |
| **Ansible / dotbot / yadm** | imperative convergence / symlinks | ❌ | ❌ | ⚠️ varies |

**Why Nix won here**

- **One model, not four.** Stow + a Brewfile + mise + a secrets tool ≈ what a
  single flake already does — minus the lockfile and the rollback.
- **Reproducible by construction.** `flake.lock` pins every input; the same lock
  rebuilds the same closure on any machine. Brew/chezmoi/mise pin loosely, or only
  per-project.
- **Atomic switch + rollback.** A failed `switch` doesn't half-apply, and a bad one
  rolls back to the previous generation. Imperative tools strand you mid-migration.
- **One config, two OSes.** The same home-manager layer builds on macOS and Linux.
- **Nothing scattered.** Tools live in the Nix store and compose into your profile —
  no drift in `/usr/local`. Per-project toolchains stay in [devenv.sh](https://devenv.sh).

**The honest cost** — Nix has the steepest learning curve of the bunch and a larger
store on disk, and GUI apps still come from Homebrew casks. The payoff: the machine
is a build artifact, not a pile of remembered steps.

**Where the others still fit** — `mise`/`devenv` shine at *per-project* runtimes;
this repo uses [devenv.sh](https://devenv.sh) for exactly that. chezmoi's templating
and secrets are deliberately out of scope — secrets stay in 1Password and client
config in a private devenv repo, never in the dotfiles.

</details>

<details>
<summary><h2>Repo structure</h2></summary>

```
dotfiles/
├── flake.nix             # inputs (unstable) + outputs (apps · checks · configs)
├── flake.lock            # pinned
├── username.nix          # the account to build for (stamped by bootstrap)
├── bootstrap.sh          # one command on a fresh machine, macOS or Linux
├── apply.sh              # rebuild wrapper behind `nix run .#mac|linux|server` — nom + nvd
├── Makefile              # task shortcuts: make apply · build · diff · update · lint
├── statix.toml           # Nix lint config (nix flake check)
├── nix/lib.nix           # flake helpers: mkDarwin · mkHome · lint · fmt
├── hosts/mac.nix         # macOS system layer + GUI casks
├── wallpaper/            # mac/ dynamic .heic (shuffled) + iphone/ png
├── .github/              # demo (tape + gif) + CI (lint/fmt on push)
└── home/
    ├── shared.nix        # portable user core (zsh, direnv) — the floor every profile stands on
    ├── workstation.nix   # shared + the desktop layer — imported by mac AND linux
    ├── darwin.nix        # macOS entry point: workstation + GUI configs + wallpaper
    ├── linux.nix         # Linux desktop entry point: workstation + Mocha
    ├── server.nix        # headless entry point: shared + Mocha, no desktop weight
    ├── theme-mocha.nix   # catppuccin/nix Mocha — Linux side only; the Mac autoswitches
    ├── tmux.nix          # tmux via programs.tmux (plugins · status · sessions)
    ├── packages/         # nixpkgs tools — core.nix (everywhere) + workstation.nix (desktop)
    ├── dotfiles/         # → read-only ~/.config symlinks, split the same core/workstation way
    └── config/           # the actual dotfiles (shell/ nvim/ zed/ wezterm/ …)
```

</details>

<details>
<summary><h2>Bootstrap</h2></summary>

One command on a fresh machine. Idempotent — every layer is skipped if already
present, so it is safe to re-run.

```bash
curl -fsSL https://raw.githubusercontent.com/mhmdio/dotfiles/main/bootstrap.sh | bash
```

- **macOS** → Xcode CLT → Lix → Homebrew → clone → `darwin-rebuild switch`
- **Linux** (non-NixOS) → Lix → clone → `home-manager switch` (no system layer; the switch needs no sudo, though installing Lix + enrolling a trusted user does)
- **Headless** → *not* this script. Once Lix and the clone exist, the no-desktop
  profile is `nix run .#server` — normally driven by the homelab repo's Ansible
  dotfiles role, not by hand. (Running `bootstrap.sh` on a server would apply the
  *desktop* Linux profile, which is exactly the weight `server.nix` exists to avoid.)

</details>

<details>
<summary><h2>Usage</h2></summary>

### What runs where

| Concern | Managed by |
|---|---|
| CLI tools everywhere, laptop or server | **nixpkgs** — `home/packages/core.nix` |
| JS runtimes (node/bun) + GUI editors (Zed, WezTerm) — desktops only | **nixpkgs** — `home/packages/workstation.nix` |
| zsh + plugins (autosuggestions, syntax-highlighting, fzf-tab), direnv | **home-manager** — `home/shared.nix` |
| Dotfiles (`~/.config/*`) imported as read-only symlinks | **home-manager** — `home/dotfiles/` → `home/config/` |
| macOS defaults, fonts, the user, system zsh *(macOS only)* | **nix-darwin** — `hosts/mac.nix` |
| macOS GUI configs (karabiner) + the shuffled wallpaper | **home-manager** — `home/darwin.nix` |
| GUI `.app` casks (1Password, Chrome, Telegram, …) *(macOS only)* | **Homebrew**, driven declaratively by nix-darwin |
| Per-client toolchains (kubectl, terraform, …) | **devenv.sh** — *never in this repo* |

**Why Homebrew at all?** Almost everything is in Nix — even things that are
casks/taps elsewhere (`wezterm`, `_1password-cli`, `maple-mono`, the
`zed-editor` app). Only GUI apps with no good nixpkgs build remain on brew.

### Daily use

`nix run .#mac` / `.#linux` drive `apply.sh`, which stages tracked files for you
(flakes only see them) and shows the live build tree via
[nix-output-monitor](https://github.com/maralorn/nix-output-monitor); the build
log stays on screen (failed switches stay debuggable), and on macOS it prints an
`nvd` diff of what changed afterwards. Everything else is a plain Nix command.

```bash
# macOS
nix run .#mac      # apply.sh mac → sudo darwin-rebuild switch --flake .#mac
nix build --dry-run .#darwinConfigurations.mac.system   # evaluate, don't apply

# Linux
nix run .#linux    # apply.sh linux → home-manager switch --flake .#<you> -b backup

# Headless (also what the homelab repo's Ansible dotfiles role runs)
nix run .#server   # apply.sh server → home-manager switch --flake .#<serverUser>-server

# native nix — run from anywhere
nix flake check    # lint + a real build of each config
nix fmt            # format every .nix file (nixfmt)
nix flake update   # bump flake.lock
nix run .#demo     # re-record the showcase gif (vhs · macOS only)
```

### nh — daily driver (Homebrew muscle-memory → Nix)

[`nh`](https://github.com/nix-community/nh) is a friendly front-end for the
build / search / garbage-collect loop (nom progress + a generation diff built
in). It's the closest thing to a daily `brew` replacement:

| Homebrew | here |
|---|---|
| `brew install foo` | add `foo` to `home/packages/core.nix` → `nh darwin switch` |
| `brew uninstall foo` | remove it from `home/packages/core.nix` → `nh darwin switch` |
| `brew search foo` | `nh search foo` |
| `brew upgrade` | `nix flake update` (bump `flake.lock`) → `nh darwin switch` |
| `brew cleanup` (+ autoremove) | `nh clean all` |

Point `nh` at this repo once so the subcommands need no path argument:

```bash
export NH_FLAKE="$HOME/Developer/dotfiles"   # adjust to your clone; add to your shell rc
```

```bash
nh darwin switch     # build + activate (sudo auto), live progress + change diff
nh search ripgrep    # find a package on nixpkgs
nh clean all         # garbage-collect old generations + the store
```

Two caveats: `nh` doesn't stage files, so run `git add -A` first (flakes only see
tracked files — `nix run .#mac` does this for you); and **GUI apps still come from
Homebrew casks** (declared in `hosts/mac.nix`) — `nh`/Nix manage the
CLI/Nix side, not casks.

`,` ([comma](https://github.com/nix-community/comma)) complements it: `, cowsay hi`
runs any nixpkg without installing it (run `nix-index` once to build its index).

### Adding / removing a tool

This is meant to be a one-line change.

- **A CLI you want everywhere**, servers included → `home/packages/core.nix`.
- **A CLI or runtime for machines you sit at** → `home/packages/workstation.nix`
  (Mac + Linux desktop; the headless profile never sees it).
- **A macOS-only CLI** → `home/darwin.nix`. **Server-only** → `home/server.nix`.
- **A macOS GUI `.app`** → add/remove a cask in `hosts/mac.nix`.
- **A dotfile** → drop it in `home/config/<tool>/` and reference it in
  `home/dotfiles/core.nix` (or `dotfiles/workstation.nix` for desktop-only,
  `home/darwin.nix` for macOS-only).

Then re-apply (`nix run .#mac` / `.#linux`). Search names at
[search.nixos.org/packages](https://search.nixos.org/packages).

</details>

<details>
<summary><h2>Packages</h2></summary>

Optional reference — every tool in [`home/packages/`](home/packages) with a
one-line note (plus fonts from `hosts/mac.nix` and tmux from `home/tmux.nix`). GUI
`.app` casks: `homebrew.casks` in `hosts/mac.nix`. Split across
[`core.nix`](home/packages/core.nix) (everywhere) and
[`workstation.nix`](home/packages/workstation.nix) (desktops only).

**core shell / file utils**

| tool | what it is |
|---|---|
| [coreutils](https://www.gnu.org/software/coreutils/) | GNU core utilities |
| [gawk](https://www.gnu.org/software/gawk/) | GNU awk |
| [gnupg](https://gnupg.org) | OpenPGP encryption (GPG) |
| [curl](https://curl.se/) | transfer data over URLs |
| [wget](https://www.gnu.org/software/wget/) | download over HTTP/FTP |
| [rsync](https://rsync.samba.org/) | incremental file sync |
| [unzip](http://www.info-zip.org) | extract `.zip` archives |
| [p7zip](https://github.com/p7zip-project/p7zip) | 7-Zip archiver |

**search / nav / viewers**

| tool | what it is |
|---|---|
| [ripgrep](https://github.com/BurntSushi/ripgrep) | fast recursive grep |
| [fd](https://github.com/sharkdp/fd) | friendly `find` |
| [fzf](https://github.com/junegunn/fzf) | fuzzy finder |
| [zoxide](https://github.com/ajeetdsouza/zoxide) | smarter `cd` |
| [eza](https://github.com/eza-community/eza) | modern `ls` |
| [bat](https://github.com/sharkdp/bat) | `cat` + syntax highlighting |
| [yazi](https://github.com/sxyazi/yazi) | terminal file manager |

**git**

| tool | what it is |
|---|---|
| [git](https://git-scm.com/) | version control |
| [git-lfs](https://git-lfs.com/) | large-file storage |
| [gh](https://cli.github.com/) | GitHub CLI (via `programs.gh`) |
| [gh-dash](https://github.com/dlvhdr/gh-dash) | PR/issue dashboard — `gh` extension, run `gh dash` (`ghd`) |
| [lazygit](https://github.com/jesseduffield/lazygit) | git TUI |
| [lazyworktree](https://github.com/chmouel/lazyworktree) | git worktree manager TUI (`lwt`) |
| [delta](https://github.com/dandavison/delta) | syntax-highlighting diff pager |

**nix helpers**

| tool | what it is |
|---|---|
| [nix-output-monitor](https://github.com/maralorn/nix-output-monitor) | pretty live build progress (nom) |
| [nh](https://github.com/nix-community/nh) | nix CLI helper (rebuild/search/GC) |
| [nvd](https://khumba.net/projects/nvd) | package version diff |
| [comma](https://github.com/nix-community/comma) | run programs without installing |
| [nix-index](https://github.com/nix-community/nix-index) | files database for nixpkgs |

**dev runtimes / build**

| tool | what it is |
|---|---|
| [gcc](https://gcc.gnu.org/) | GNU compiler collection |
| [nodejs_24](https://nodejs.org) | Node.js 24 runtime |
| [bun](https://bun.sh) | JS runtime + bundler + PM |
| [pnpm](https://pnpm.io/) | fast JS package manager |
| [tree-sitter](https://github.com/tree-sitter/tree-sitter) | incremental parser |
| [devenv](https://github.com/cachix/devenv) | per-project dev shells (devenv.sh) |

**editor / multiplexer**

| tool | what it is |
|---|---|
| [neovim](https://neovim.io) | text editor |
| [tmux](https://tmux.github.io/) | terminal multiplexer |

**system / disk / containers**

| tool | what it is |
|---|---|
| [btop](https://github.com/aristocratos/btop) | resource monitor |
| [dust](https://github.com/bootandy/dust) | intuitive `du` |
| [duf](https://github.com/muesli/duf/) | disk usage / free |
| [gping](https://github.com/orf/gping) | ping with a graph |
| [lazydocker](https://github.com/jesseduffield/lazydocker) | docker TUI |
| [docker](https://www.docker.com/) | container CLI (talks to the colima VM) |
| [docker-compose](https://docs.docker.com/compose/) | multi-container orchestration |
| [colima](https://github.com/abiosoft/colima) | rootless Docker VM — replaces Docker Desktop (`colima start`) |

**data / http / net**

| tool | what it is |
|---|---|
| [jq](https://jqlang.github.io/jq/) | JSON processor |
| [jnv](https://github.com/ynqa/jnv) | interactive `jq` filter builder |
| [fx](https://github.com/antonmedv/fx) | interactive JSON viewer / processor |
| [yq-go](https://mikefarah.gitbook.io/yq/) | YAML processor |
| [httpie](https://httpie.org/) | human-friendly HTTP client |
| [xh](https://github.com/ducaale/xh) | fast HTTP client (`curl`/`httpie`) |
| [posting](https://github.com/darrenburns/posting) | API client TUI — terminal Postman (`posting`) |
| [doggo](https://github.com/mr-karan/doggo) | DNS client |
| [trippy](https://github.com/fujiapple852/trippy) | traceroute + ping TUI (`trip`) |
| [bandwhich](https://github.com/imsnif/bandwhich) | network usage by process |
| [rclone](https://rclone.org) | sync to/from cloud storage |

**power CLIs**

| tool | what it is |
|---|---|
| [pandoc](https://pandoc.org) | document converter |
| [killport](https://github.com/jkfran/killport) | kill the process on a port |
| [pwgen](https://github.com/tytso/pwgen) | password generator |
| [ast-grep](https://ast-grep.github.io/) | structural code search/rewrite |
| [scc](https://github.com/boyter/scc) | fast code counter |
| [starship](https://starship.rs) | shell prompt |
| [atuin](https://github.com/atuinsh/atuin) | shell history on Ctrl-R (SQLite, stats, sync) |
| [sd](https://github.com/chmln/sd) | `sed` alternative |
| [choose](https://github.com/theryangeary/choose) | human-friendly `cut`/`awk` |
| [viddy](https://github.com/sachaos/viddy) | modern `watch` |
| [hyperfine](https://github.com/sharkdp/hyperfine) | CLI benchmarking |
| [tealdeer](https://github.com/tealdeer-rs/tealdeer) | fast `tldr` pages |

**AI / agent**

| tool | what it is |
|---|---|
| [opencode](https://opencode.ai) | terminal AI coding agent |

**fetch / pretty**

| tool | what it is |
|---|---|
| [fastfetch](https://github.com/fastfetch-cli/fastfetch) | system info (neofetch-like) |
| [glow](https://github.com/charmbracelet/glow) | render markdown in the terminal |
| [gum](https://github.com/charmbracelet/gum) | shell-script UI toolkit |
| [hackernews-tui](https://github.com/aome510/hackernews-TUI) | Hacker News reader (`hn`) |
| [bagels](https://github.com/EnhancedJax/Bagels) | expense tracker TUI (`bagels`) |
| [harlequin](https://harlequin.sh/) | SQL IDE for the terminal (`harlequin`) |
| [cloudlens](https://github.com/one2nc/cloudlens) | k9s-like TUI for AWS/GCP (`cloudlens`) |

**recording / media**

| tool | what it is |
|---|---|
| [asciinema](https://asciinema.org/) | terminal session recorder |
| [ffmpeg](https://www.ffmpeg.org/) | audio/video convert & stream |
| [imagemagick](https://imagemagick.org/) | image convert & edit |
| [yt-dlp](https://github.com/yt-dlp/yt-dlp) | video/audio downloader (YouTube + 1000s of sites) |

**GUI apps (from nixpkgs)**

| tool | what it is |
|---|---|
| [_1password-cli](https://developer.1password.com/docs/cli/) | 1Password CLI (`op`) |
| [wezterm](https://wezterm.org) | GPU terminal emulator |
| [zed-editor](https://zed.dev) | code editor (CLI: `zeditor`) |

**fonts & macOS extras (nix)**

| tool | what it is |
|---|---|
| [maple-mono](https://github.com/subframe7536/Maple-font) | Maple Mono NF — UI/editor font |
| [nerd-fonts](https://nerdfonts.com/) | Fira Code · Hack · JetBrains Mono |
| [mas](https://github.com/mas-cli/mas) | Mac App Store CLI |

</details>

<details>
<summary><h2>Fork</h2></summary>

**No username to set** — `bootstrap.sh` stamps the running account into
`username.nix`, which the flake reads (pure eval), so the same config builds for
any user on any machine with no manual edit. Just adjust the cask list in
`hosts/mac.nix` to taste. (Applying by hand instead of via bootstrap?
Put your account in `username.nix`; it defaults to `mohammed`.)

</details>

<details>
<summary><h2>Theme</h2></summary>

**No switcher command and no rebuild.** Almost every tool detects the terminal's
background colour and autoswitches **Catppuccin** itself (Mocha = dark, Latte =
light):

- **bat** → `--theme=auto` + `--theme-dark`/`--theme-light` (both ship with bat)
- **delta** → `detect-dark-light = auto`
- **btop** / **tmux** → the terminal's own 16 ANSI colours, so they never need a flavour
- **nvim** → catppuccin `flavour = "auto"` (nvim detects the terminal background)
- **yazi** / **glow** → native dark/light auto-detection
- **WezTerm** & **Zed** detect the OS appearance natively
- **starship** uses one palette-agnostic config
- **wallpaper** → dynamic `.heic`s, each carrying its own light and dark image (see [Thanks](#thanks))

WezTerm itself switches its Catppuccin Mocha/Latte palette with the OS, so the
16 ANSI colours everything reads also flip. Toggle the OS appearance — terminal
tools follow live, GUI apps on relaunch.

**One exception, and it's deliberate: [gh-dash](https://github.com/dlvhdr/gh-dash).**
It can't autoswitch — its config takes one colour per role, and lipgloss flattens
adaptive colours to concrete RGB before they reach the terminal, so a configured
ANSI index never survives. It ships two theme files
(`home/config/gh-dash/theme-{mocha,latte}.yml`, appended to a shared base at build
time) and the `ghd` shell function reads `AppleInterfaceStyle` to pick one at
launch. That's the only shell glue and the only hand-written theme in the repo.
Two honest limits: the flavour is chosen when the dashboard starts, so it won't
follow a switch mid-session, and plain `gh dash` (rather than `ghd`) always gets
Mocha.

The Linux profiles skip all of this and pin Mocha through
[catppuccin/nix](https://github.com/catppuccin/nix) (`home/theme-mocha.nix`) —
there's no OS appearance to follow over SSH.

</details>

<details>
<summary><h2>⌨️ Keyboard shortcuts</h2></summary>

Two modifier **foundations**, set in Karabiner (`home/config/karabiner/karabiner.json`) on the Logitech MX Keys Mini — everything builds on these:

| Foundation | Keys | Role |
|---|---|---|
| **Hyper** | Right Option → `⌃⌥⇧⌘` | Global namespace — app launch + window/space actions (bound in Raycast's GUI). No app uses all four mods, so nothing collides. |
| **Caps → Ctrl** | hold `Caps` = `Ctrl`, double-tap = `Esc` | The comfortable Ctrl for the terminal/editor (tmux, nvim, zsh vi-mode). |

### WezTerm — leader `Ctrl+Shift+a` (= Caps+Shift+a)

| Keys | Action |
|---|---|
| `⌘P` | command palette (Leader `?` aliases it) — plus `tab: rename…`, `tmux: switch session…`, `tmux: rename session/window…` |
| Leader `-` / `\|` | split down / right |
| Leader `h j k l` · Leader `⇧ hjkl` | focus pane · resize pane |
| Leader `r` | resize mode (then `hjkl`, `Esc`) |
| Leader `Space` · `f` · `=` · `o` · `q` | pane picker · zoom · swap · rotate · close |
| Leader `t` · `[` `]` · `1`–`9` · `Tab` · `,` | new tab · prev/next · jump N · last · rename (empty = back to auto) |
| Leader `w` · `{` `}` · `$` | workspace switcher · prev/next · rename |
| Leader `Enter` / `s` · `y` / `v` · `/` | copy-mode / quick-select · copy / paste · search |
| Leader `m` · `⇧ f` · `⇧ r` | launcher (btop/yazi/lazygit) · fullscreen · reload |

Source: `home/config/wezterm/wezterm.lua`.

### tmux — prefix `Ctrl+b`

| Keys | Action |
|---|---|
| Prefix `\|` / `-` | split horizontal / vertical (keep path) |
| Prefix `h j k l` · Prefix `⇧ HJKL` | select pane · resize |
| Prefix `f` | session picker popup (`t` in the shell) — `↵` attach · `^x` kill (asks first) · `^/` preview |
| Prefix `r` | reload config |
| copy-mode `v` / `y` | begin selection / copy (vi) |

Source: `home/config/tmux/tmux.conf`.

**One session per WezTerm tab.** The tab is the project; tmux windows are tasks
inside it. Everything that switches sessions keeps that 1:1: the picker (`t`,
prefix `f`) and `⌘P → tmux: switch session…` *focus the tab* a session is already
attached to and only open a new tab for a detached one — never `switch-client`,
which would put two clients on one session and shrink both to the smaller. Tab
titles follow the session name automatically (`set-titles`), and Leader `,`
overrides that per tab. Sessions outlive the terminal, so closing WezTerm loses
nothing; resurrect/continuum bring them back after a reboot.

### Neovim — leader `Space`

Stock **LazyVim** keymaps plus a few plugin rebinds: `Ctrl-h/j/k/l` navigates nvim splits *and* tmux panes (vim-tmux-navigator), `<leader>-` opens yazi at the current file (replacing LazyVim's split-below), `Ctrl-Up` resumes it. `Space` opens which-key. See the [LazyVim keymaps](https://www.lazyvim.org/keymaps).

### Yazi & Lazygit

- **Yazi**: `g i` → lazygit; otherwise stock vi-style nav. (`home/config/yazi/keymap.toml`)
- **Lazygit**: stock defaults. (`home/config/lazygit/config.yml`)

### Shell — zsh vi-mode + fzf

| Keys | Action |
|---|---|
| `Ctrl+R` | shell history search (Atuin — SQLite, stats, exit codes, optional sync) |
| `Ctrl+T` · `Alt+C` | insert file/dir path · cd into a dir |
| `Tab` | fzf-tab completion (with previews) |
| `Esc` (or double-tap Caps) · `v` | vi normal mode · edit command in `$EDITOR` |
| `Ctrl+A/E` · `Ctrl+K/U/W` · `Ctrl+Y` | line start/end · kill line/line-back/word · yank |

Aliases: `ls`→eza · `cat`→bat · `lt` tree · `cd`→zoxide · `y` yazi-cd · `v`/`n` nvim · `lg` lazygit · `hn` Hacker News · `g` + git shorthands. Type **`help`** for a colour cheatsheet of the modern-CLI replacements. Source: `home/config/shell/*.zsh`.

</details>

<details>
<summary><h2>Notes</h2></summary>

- **nixpkgs-unstable** across nixpkgs / nix-darwin / home-manager (latest tool versions).
- **`nix.enable = false`** — Lix owns Nix; nix-darwin doesn't manage the daemon.
- **`allowUnfree = true`** — for the 1Password CLI, etc.
- **Scope = your daily tools only.** Per-client CLIs are out of scope by design —
  they belong in [devenv.sh](https://devenv.sh) shells, not here.
- **Homebrew casks are declarative** (zap-prune on activation) — a cask installed by
  hand but not added to `hosts/mac.nix` is removed on the next `nix run .#mac`.
- **Wallpaper** — shuffled from `wallpaper/mac/` on every switch, at login, and hourly
  (`wallpaper-shuffle`, a launchd agent; run it by hand to reroll). The first
  `nix run .#mac` may prompt to allow controlling System Events so it can set the
  desktop picture — approve once.

</details>

<details>
<summary><h2>Roadmap</h2></summary>

**Coverage** — OSes the config targets

- [x] macOS
- [x] Linux (non-NixOS)
- [ ] WSL2 — via [NixOS-WSL](https://github.com/nix-community/NixOS-WSL) (full NixOS,
  not standalone home-manager); see the commented `nixosConfigurations.wsl` in `flake.nix`

**Test** — verified end-to-end on a fresh machine

- [x] macOS
- [ ] Linux
- [ ] WSL2

</details>

<details>
<summary><h2>Links</h2></summary>

**Nix layer**
- [Lix](https://lix.systems) — the Nix interpreter/daemon this repo installs
- [nix-darwin options](https://nix-darwin.github.io/nix-darwin/manual/) — every `system.defaults` / system key
- [home-manager options](https://nix-community.github.io/home-manager/options.xhtml) — user-layer options
- [search.nixos.org/packages](https://search.nixos.org/packages) — find a package name
- [MyNixOS — nix-darwin](https://mynixos.com/nix-darwin/options/system.defaults) — searchable defaults reference

**Per-client toolchains**
- [devenv.sh](https://devenv.sh) — per-project reproducible shells
- [direnv](https://direnv.net) — auto-loads a shell on `cd`

**Tools**
- [WezTerm](https://wezterm.org) · [Neovim](https://neovim.io) / [LazyVim](https://www.lazyvim.org) · [Yazi](https://yazi-rs.github.io) · [lazygit](https://github.com/jesseduffield/lazygit) · [tmux](https://github.com/tmux/tmux/wiki)
- [Starship](https://starship.rs) · [zoxide](https://github.com/ajeetdsouza/zoxide) · [fzf](https://github.com/junegunn/fzf) · [fzf-tab](https://github.com/Aloxaf/fzf-tab) · [eza](https://eza.rocks) · [bat](https://github.com/sharkdp/bat) · [ripgrep](https://github.com/BurntSushi/ripgrep) · [fd](https://github.com/sharkdp/fd) · [delta](https://github.com/dandavison/delta)

**Theme**
- [Catppuccin](https://catppuccin.com) — the Mocha/Latte palette every tool follows
- [BasicAppleGuy](https://basicappleguy.com) — the *Topographic Amoeba* wallpapers in `wallpaper/`

</details>

<details>
<summary><h2>Thanks</h2></summary>

- **[BasicAppleGuy](https://basicappleguy.com)** for the
  [*Topographic Amoeba*](https://basicappleguy.com/basicappleblog/topographic-amoeba)
  collection in [`wallpaper/`](wallpaper) — six wallpapers offered free and in full
  resolution. The Mac files are dynamic HEICs, so each one carries its own light and
  dark image and macOS swaps between them with the system appearance; `wallpaper-shuffle`
  just picks which of the six is up. If you use them, consider
  [supporting the work](https://basicappleguy.com/basicappleblog/topographic-amoeba).
- **[Catppuccin](https://catppuccin.com)** for the palette every tool in here follows.

</details>
