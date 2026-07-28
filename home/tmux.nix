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
  # Under WezTerm it keeps one session per tab: an attached session means "focus
  # that tab", a detached one gets a new tab. Elsewhere it's plain switch-client.
  tmux-sessionizer = pkgs.writeShellApplication {
    name = "tmux-sessionizer";
    runtimeInputs = [
      pkgs.fzf
      pkgs.tmux
      pkgs.coreutils
      pkgs.jq # tab lookup in `wezterm cli list --format json`
    ];
    text = ''
      TAB=$'\t'

      # `--preview <session>` is the fzf preview pane, re-entering this script so
      # the listing can be written as plain shell. It shows what the session HOLDS
      # — windows, and the panes inside them — rather than the live text of one
      # pane: the picker is for finding a session, and "3 windows, nvim + claude +
      # a shell in ~/Developer/dotfiles" identifies one faster than its scrollback.
      if [ "''${1:-}" = "--preview" ]; then
        sess="''${2:-}"
        [ -n "$sess" ] || exit 0
        # Same claude-version-as-a-name substitution as automatic-rename-format in
        # tmux.conf — it fixes new renames, not names already on old windows.
        name_fmt="#{s|^[0-9][0-9.]*$|claude|:%s}"
        windows="$(tmux list-windows -t "=$sess" \
          -F "#{window_index}''${TAB}''${name_fmt/\%s/window_name}''${TAB}#{window_active}''${TAB}#{window_panes}" \
          2>/dev/null || true)"
        while IFS="$TAB" read -r idx wname wactive wpanes; do
          [ -n "$idx" ] || continue
          mark="  "
          if [ "$wactive" = 1 ]; then mark=$'\033[34m▸\033[0m '; fi
          panes="$(tmux list-panes -t "=$sess:$idx" \
            -F "#{pane_index}''${TAB}''${name_fmt/\%s/pane_current_command}''${TAB}#{pane_current_path}''${TAB}#{pane_active}" \
            2>/dev/null || true)"
          # A one-pane window IS its pane — fold the path up onto the window line
          # instead of repeating the command under it. Only splits get a list.
          if [ "$wpanes" = 1 ]; then
            IFS="$TAB" read -r _ _ ppath _ <<< "$panes"
            printf '%s\033[1m%-16s\033[0m \033[2m%s\033[0m\n' "$mark" "$idx: $wname" "''${ppath/#$HOME/\~}"
            continue
          fi
          printf '%s\033[1m%-16s\033[0m \033[2m%s panes\033[0m\n' "$mark" "$idx: $wname" "$wpanes"
          while IFS="$TAB" read -r pidx pcmd ppath pactive; do
            [ -n "$pidx" ] || continue
            short="''${ppath/#$HOME/\~}"
            if [ "$pactive" = 1 ]; then
              printf '     \033[34m%s\033[0m %-12s \033[2m%s\033[0m\n' "$pidx" "$pcmd" "$short"
            else
              printf '     \033[2m%s %-12s %s\033[0m\n' "$pidx" "$pcmd" "$short"
            fi
          done <<< "$panes"
        done <<< "$windows"
        exit 0
      fi

      current=""
      if [ -n "''${TMUX:-}" ]; then
        current="$(tmux display-message -p '#S')"
      fi

      # The picker list, as fzf lines: field 1 = raw session name (hidden),
      # field 2 = what's displayed. A function because ^x kills a session and then
      # asks fzf to reload — same code path, so the reloaded list can't drift.
      emit_list() {
        sessions="$(tmux list-sessions \
          -F "#{session_name}''${TAB}#{session_windows}''${TAB}#{session_attached}''${TAB}#{session_activity}" \
          2>/dev/null || true)"
        now="$(date +%s)"
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
          printf '%s\t%s \033[1m%-18s\033[0m \033[2m%2s win\033[0m  %s \033[2m· %s\033[0m\n' \
            "$name" "$dot" "$name" "$windows" "$state" "$when"
        done <<< "$sessions"
      }

      # fzf's reload target.
      if [ "''${1:-}" = "--list" ]; then
        emit_list
        exit 0
      fi

      # ^x in the picker. Killing a session takes everything running in it with
      # it — claude mid-answer, a dev server, an ssh — so it asks first. It lives
      # here rather than inline in the --bind so the quoting stays readable and
      # the confirm can be tested on its own.
      if [ "''${1:-}" = "--kill" ]; then
        sess="''${2:-}"
        [ -n "$sess" ] || exit 0
        printf '\n  kill \033[1m%s\033[0m and everything running in it? [y/N] ' "$sess"
        read -r reply
        case "$reply" in
          [yY]*) tmux kill-session -t "=$sess" 2>/dev/null || true ;;
        esac
        exit 0
      fi

      if [ "$#" -eq 1 ]; then
        target="$1"
      else
        list="$(emit_list)"

        if [ -z "$list" ]; then
          msg='no tmux sessions to pick — t <dir> starts one'
          if [ -n "''${TMUX:-}" ]; then tmux display-message "$msg"; else echo "$msg"; fi
          exit 0
        fi

        # fzf runs the preview through `sh -c`, so hand it an absolute path rather
        # than trusting that subshell's PATH.
        self="$(command -v "$0" 2>/dev/null || true)"
        [ -n "$self" ] || self="$0"

        # The popup already draws a rounded, accented frame with a title, so fzf
        # runs borderless inside it and marks its own sections with hairlines
        # instead: a rule under the prompt, one above the key hints, one down the
        # side of the preview. Grey (ANSI 8) keeps them structural, not loud.
        #
        # {1} is the hidden raw name column, and fzf shell-quotes it, so `-t ={1}`
        # arrives as tmux's exact-match `=name` with the quotes around the name
        # only — hence no quotes of our own around it.
        target="$(
          printf '%s' "$list" | fzf --ansi --reverse --border=none \
            --prompt='  ' --pointer='▶' \
            --delimiter="$TAB" --with-nth=2 --nth=2 \
            --preview "$self --preview {1}" \
            --preview-window='right,55%,border-left' \
            --input-border=bottom --footer-border=top \
            --footer='  ↑↓ move   ↵ attach   ^x kill   ^/ preview   esc quit' \
            --color='footer:8,footer-border:8,input-border:8,preview-border:8' \
            --bind="ctrl-x:execute($self --kill {1})+reload($self --list)" \
            --bind='ctrl-j:down,ctrl-k:up' \
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
      fi

      # Inside tmux. One session per WezTerm tab, so prefer moving the EYE to the
      # session rather than the session to this tab: switch-client would leave two
      # tabs on one session, and tmux then shrinks both clients to the smaller.
      #
      # Resolving the tab has to go through ttys: $WEZTERM_PANE is inherited from
      # the tmux server's environment, so every pane claims to be the tab the
      # server was started in. A client's tty IS its WezTerm pane's tty.
      if command -v wezterm >/dev/null 2>&1; then
        # Every lookup is `|| true`: set -e would otherwise abort the picker just
        # because a session has no client or the GUI isn't reachable.
        tty="$(tmux list-clients -t "=$name" -F '#{client_tty}' 2>/dev/null | head -1 || true)"
        panes="$(wezterm cli list --format json 2>/dev/null || true)"

        if [ -n "$tty" ] && [ -n "$panes" ]; then
          # Already attached somewhere: focus that tab.
          tab="$(printf '%s' "$panes" \
            | jq -r --arg t "$tty" 'map(select(.tty_name == $t)) | .[0].tab_id // empty' || true)"
          if [ -n "$tab" ]; then
            exec wezterm cli activate-tab --tab-id "$tab"
          fi
        elif [ -n "$panes" ]; then
          # Detached (e.g. restored by continuum): give it a tab of its own.
          here="$(tmux display-message -p '#{client_tty}' 2>/dev/null || true)"
          pane="$(printf '%s' "$panes" \
            | jq -r --arg t "$here" 'map(select(.tty_name == $t)) | .[0].pane_id // empty' || true)"
          if [ -n "$pane" ]; then
            exec wezterm cli spawn --pane-id "$pane" -- tmux attach -t "=$name"
          fi
        fi
      fi

      # Not WezTerm (plain terminal, ssh, Linux): plain tmux behaviour.
      exec tmux switch-client -t "=$name"
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
          set -g status-right "#[fg=blue] #[fg=default]#{cpu_percentage}  #[fg=blue] #[fg=default]#{ram_percentage}  #[fg=blue] #[fg=default]#(df -h / | awk 'NR==2{print $5}')  "
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
