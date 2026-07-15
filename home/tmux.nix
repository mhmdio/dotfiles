# tmux — declarative multiplexer. Structural options + plugins are wired here
# (reproducible: plugins come from nixpkgs, no tpm / runtime git clones). The
# keybindings and status line live in the hand-written config/tmux/tmux.conf,
# read in below as extraConfig.
{ pkgs, ... }:
let
  # Session picker: pretty fzf list of live tmux sessions (current one excluded)
  # — attached/detached dot, windows count, last activity — with a live
  # capture-pane preview. Pick one → attach/switch. `t <dir|session>` skips the
  # picker: a dir creates a session named after it (if missing) and jumps in.
  # Bound to prefix+f (popup) and exposed as the `t` shell command.
  tmux-sessionizer = pkgs.writeShellApplication {
    name = "tmux-sessionizer";
    runtimeInputs = [
      pkgs.fzf
      pkgs.tmux
      pkgs.coreutils
    ];
    text = ''
      TAB=$'\t'

      current=""
      if [ -n "''${TMUX:-}" ]; then
        current="$(tmux display-message -p '#S')"
      fi

      if [ "$#" -eq 1 ]; then
        target="$1"
      else
        sessions="$(tmux list-sessions \
          -F "#{session_name}''${TAB}#{session_windows}''${TAB}#{session_attached}''${TAB}#{session_activity}" \
          2>/dev/null || true)"

        # Two fzf columns: field 1 = raw session name (hidden), field 2 = display.
        now="$(date +%s)"
        list=""
        while IFS="$TAB" read -r name windows attached activity; do
          if [ -z "$name" ] || [ "$name" = "$current" ]; then continue; fi
          age=$((now - activity))
          if [ "$age" -lt 60 ]; then when="just now"
          elif [ "$age" -lt 3600 ]; then when="$((age / 60))m ago"
          elif [ "$age" -lt 86400 ]; then when="$((age / 3600))h ago"
          else when="$((age / 86400))d ago"; fi
          if [ "$attached" -gt 0 ]; then
            dot=$'\033[1;32m●\033[0m' state=$'\033[32mattached\033[0m'
          else
            dot=$'\033[1;34m○\033[0m' state=$'\033[2mdetached\033[0m'
          fi
          printf -v line '%s\t%s \033[1m%-18s\033[0m \033[2m%2s win\033[0m  %s \033[2m· %s\033[0m' \
            "$name" "$dot" "$name" "$windows" "$state" "$when"
          list+="$line"$'\n'
        done <<< "$sessions"

        if [ -z "$list" ]; then
          msg='no tmux sessions to pick — t <dir> starts one'
          if [ -n "''${TMUX:-}" ]; then tmux display-message "$msg"; else echo "$msg"; fi
          exit 0
        fi

        target="$(
          printf '%s' "$list" | fzf --ansi --reverse --border \
            --prompt='session ❯ ' --border-label=' tmux sessions ' \
            --header='↵ attach · esc quit' \
            --delimiter="$TAB" --with-nth=2 --nth=2 \
            --preview 'tmux capture-pane -ep -t {1}' \
            --preview-window='right,55%,border-left' \
            || true
        )"
        target="''${target%%"''${TAB}"*}"
      fi

      if [ -z "''${target:-}" ]; then
        exit 0
      fi

      if [ -d "$target" ]; then
        name="$(basename "$target" | tr '. ' '__')"
        if ! tmux has-session -t "=$name" 2>/dev/null; then
          tmux new-session -ds "$name" -c "$target"
        fi
      else
        name="$target"
      fi

      if [ -z "''${TMUX:-}" ]; then
        exec tmux attach -t "=$name"
      else
        exec tmux switch-client -t "=$name"
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
