# tmux — declarative multiplexer. Structural options + plugins are wired here
# (reproducible: plugins come from nixpkgs, no tpm / runtime git clones). The
# keybindings and status line live in the hand-written config/tmux/tmux.conf,
# read in below as extraConfig.
{ pkgs, ... }:
let
  # Project switcher (ThePrimeagen-style): fzf-pick a directory under ~/Developer
  # and create/attach a tmux session named after it — one session per project.
  # Bound to prefix+f (popup) and exposed as the `t` shell command.
  tmux-sessionizer = pkgs.writeShellApplication {
    name = "tmux-sessionizer";
    runtimeInputs = [
      pkgs.fzf
      pkgs.fd
      pkgs.tmux
      pkgs.coreutils
    ];
    text = ''
      if [ "$#" -eq 1 ]; then
        selected=$1
      else
        selected=$(
          {
            fd --type d --min-depth 1 --max-depth 1 . "$HOME/Developer" 2>/dev/null || true
            fd --type d --min-depth 1 --max-depth 2 . "$HOME/Developer/work" 2>/dev/null || true
          } | fzf --prompt='project ❯ ' --reverse --border || true
        )
      fi

      if [ -z "''${selected:-}" ]; then
        exit 0
      fi

      name=$(basename "$selected" | tr '. ' '__')

      if ! tmux has-session -t="$name" 2>/dev/null; then
        tmux new-session -ds "$name" -c "$selected"
      fi

      if [ -z "''${TMUX:-}" ]; then
        tmux attach -t "$name"
      else
        tmux switch-client -t "$name"
      fi
    '';
  };
in
{
  home.packages = [ tmux-sessionizer ];

  programs.tmux = {
    enable = true;
    prefix = "C-b"; # tmux default; C-' is the ergonomic second prefix (see tmux.conf)
    keyMode = "vi";
    mouse = true;
    baseIndex = 1;
    escapeTime = 10;
    historyLimit = 100000;
    terminal = "tmux-256color";
    focusEvents = true;

    # Load order matters: navigator/yank first, resurrect next, continuum LAST —
    # continuum's hook has to be the final run-shell line to auto-save/restore.
    plugins = with pkgs.tmuxPlugins; [
      vim-tmux-navigator
      yank
      {
        # status-right MUST be set here, not in the main extraConfig: home-manager
        # emits per-plugin extraConfig right before this plugin's run-shell, but the
        # main extraConfig comes AFTER all plugins. cpu.tmux rewrites the
        # #{cpu_percentage}/#{ram_percentage} placeholders in place, so they have to
        # already be in status-right when it runs. Disk is a plain inline df. No clock.
        plugin = cpu;
        extraConfig = ''
          set -g status-right-length 60
          set -g status-right "#[fg=magenta] CPU #[fg=default]#{cpu_percentage} #[fg=magenta]RAM #[fg=default]#{ram_percentage} #[fg=magenta]DISK #[fg=default]#(df -h / | awk 'NR==2{print $5}') "
        '';
      }
      {
        plugin = resurrect;
        extraConfig = ''
          set -g @resurrect-capture-pane-contents 'on'
          set -g @resurrect-strategy-nvim 'session'
          set -g @resurrect-processes '"~claude" ssh'
        '';
      }
      {
        plugin = continuum;
        extraConfig = ''
          set -g @continuum-restore 'on'
          set -g @continuum-save-interval '15'
        '';
      }
    ];

    extraConfig = builtins.readFile ./config/tmux/tmux.conf;
  };
}
