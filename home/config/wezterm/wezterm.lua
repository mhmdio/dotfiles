local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Catppuccin palettes — the single source of truth all tools follow.
local themes = {
	dark = {
		color_scheme = "Catppuccin Mocha",
		frame_bg = "#181825",
		frame_fg = "#cdd6f4",
		active_bg = "#1e1e2e",
		active_fg = "#cdd6f4",
		inactive_bg = "#181825",
		inactive_fg = "#45475a",
		hover_bg = "#313244",
		hover_fg = "#cdd6f4",
		new_tab_bg = "#181825",
		new_tab_fg = "#89b4fa",
		new_tab_hover_bg = "#313244",
		palette_bg = "#1e1e2e",
		palette_fg = "#cdd6f4",
		bell = "#313244", -- surface0: a flash, not a blackout
		leader_bg = "#f38ba8", -- status badges (red / yellow on base)
		leader_fg = "#1e1e2e",
		ktable_bg = "#f9e2af",
		ktable_fg = "#1e1e2e",
		opacity = 0.90,
	},
	light = {
		color_scheme = "Catppuccin Latte",
		frame_bg = "#e6e9ef",
		frame_fg = "#4c4f69",
		active_bg = "#eff1f5",
		active_fg = "#4c4f69",
		inactive_bg = "#e6e9ef",
		inactive_fg = "#bcc0cc",
		hover_bg = "#ccd0da",
		hover_fg = "#4c4f69",
		new_tab_bg = "#e6e9ef",
		new_tab_fg = "#1e66f5",
		new_tab_hover_bg = "#ccd0da",
		palette_bg = "#eff1f5",
		palette_fg = "#4c4f69",
		bell = "#ccd0da",
		leader_bg = "#d20f39",
		leader_fg = "#eff1f5",
		ktable_bg = "#df8e1d",
		ktable_fg = "#4c4f69", -- dark on Latte's gold; white washes out
		-- Light schemes lose contrast to a bright desktop much faster than dark
		-- ones, so the glass is thinner here.
		opacity = 0.96,
	},
}

local function theme_for_appearance(appearance)
	if appearance:find("Dark") then
		return themes.dark
	else
		return themes.light
	end
end

local function apply_theme(cfg, t)
	cfg.color_scheme = t.color_scheme
	cfg.window_frame = {
		font = wezterm.font({ family = "Maple Mono NF", weight = "Bold" }),
		font_size = 16,
		active_titlebar_bg = t.frame_bg,
		inactive_titlebar_bg = t.frame_bg,
	}
	cfg.colors = cfg.colors or {}
	cfg.colors.tab_bar = {
		background = t.frame_bg,
		active_tab = { bg_color = t.active_bg, fg_color = t.active_fg, intensity = "Bold" },
		inactive_tab = { bg_color = t.inactive_bg, fg_color = t.inactive_fg },
		inactive_tab_hover = { bg_color = t.hover_bg, fg_color = t.hover_fg, italic = false },
		new_tab = { bg_color = t.new_tab_bg, fg_color = t.new_tab_fg },
		new_tab_hover = { bg_color = t.new_tab_hover_bg, fg_color = t.new_tab_fg, italic = false },
	}
	cfg.colors.visual_bell = t.bell
	cfg.command_palette_bg_color = t.palette_bg
	cfg.command_palette_fg_color = t.palette_fg
	cfg.window_background_opacity = t.opacity
end

-- Font (Regular as the default weight so bold renders as actual emphasis; the
-- tab-bar/window-frame stays Bold below)
config.font = wezterm.font("Maple Mono NF")
config.font_size = 16
config.harfbuzz_features = { "calt=1", "clig=1", "liga=1" }
config.freetype_load_target = "Light"

-- Window (opacity is per-appearance — set in apply_theme)
config.macos_window_background_blur = 20
config.window_decorations = "RESIZE"
-- small padding so text doesn't butt against the window edge / blur
config.window_padding = { left = 10, right = 10, top = 8, bottom = 8 }
config.window_close_confirmation = "NeverPrompt"
config.adjust_window_size_when_changing_font_size = false

-- Bell (flash colour is themed — see apply_theme; a fixed dark grey flashed
-- near-black on Latte, and the appearance-switch override dropped it entirely)
config.audible_bell = "Disabled"
config.visual_bell = {
	fade_in_function = "EaseIn",
	fade_in_duration_ms = 150,
	fade_out_function = "EaseOut",
	fade_out_duration_ms = 150,
}

-- Tabs
config.use_fancy_tab_bar = true
config.tab_max_width = 32
config.hide_tab_bar_if_only_one_tab = true
config.show_new_tab_button_in_tab_bar = true
config.switch_to_last_active_tab_when_closing_tab = true
config.tab_and_split_indices_are_zero_based = false

-- Cursor
config.default_cursor_style = "SteadyBlock"
config.cursor_thickness = 2
-- No force_reverse_video_cursor: it overrides the scheme's cursor_fg/bg/border,
-- so the cursor stopped following Catppuccin (which defines rosewater for both
-- flavours). Reverse video guarantees contrast anywhere, so flip it back if a
-- cursor ever disappears against an odd background.

-- Mouse
config.hide_mouse_cursor_when_typing = true
config.pane_focus_follows_mouse = false
config.mouse_bindings = {
	-- Copy on select
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "NONE",
		action = wezterm.action.CompleteSelection("ClipboardAndPrimarySelection"),
	},
	-- Cmd+click to open hyperlinks (suppresses normal click handling)
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "CMD",
		action = wezterm.action.OpenLinkAtMouseCursor,
	},
	-- Prevent the click that focuses the pane from also sending input
	{
		event = { Down = { streak = 1, button = "Left" } },
		mods = "CMD",
		action = wezterm.action.Nop,
	},
}

-- Hyperlinks: URLs, file paths, mailto (built-in defaults are good)
config.hyperlink_rules = wezterm.default_hyperlink_rules()

-- Scrollback
config.scrollback_lines = 100000

-- Performance
config.front_end = "WebGpu"
config.max_fps = 120
config.animation_fps = 60
config.automatically_reload_config = true

-- Keyboard: the Kitty keyboard protocol only. Apps (Neovim, claude) negotiate
-- enhanced key encoding on demand — disambiguates C-h from Backspace (so the
-- vim-tmux-navigator C-h works), carries Shift+Enter into claude, and is
-- forward-compatible. enable_csi_u_key_encoding is deliberately OFF: the WezTerm
-- docs call it "generally not recommended" — it forces an encoding apps can't
-- detect or opt out of, breaking some keys. Kitty protocol is the negotiated path.
config.enable_kitty_keyboard = true

-- Command palette (colors set in apply_theme)
config.command_palette_font_size = 16

-- Launcher entries (fuzzy launcher on Leader+m)
config.launch_menu = {
	{ label = "btop", args = { "btop" } },
	{ label = "yazi", args = { "yazi" } },
	{ label = "lazygit", args = { "lazygit" } },
}

-- Apply themed tab bar + scheme based on macOS appearance
apply_theme(config, theme_for_appearance(wezterm.gui.get_appearance()))

wezterm.on("window-config-reloaded", function(window, _)
	local overrides = window:get_config_overrides() or {}
	local target = theme_for_appearance(window:get_appearance())
	if overrides.color_scheme ~= target.color_scheme then
		apply_theme(overrides, target)
		window:set_config_overrides(overrides)
	end
end)

-- Name the default workspace "WezTerm" (instead of "default") — shows in the
-- right status bar and the Leader+w workspace switcher.
config.default_workspace = "WezTerm"

-- ── Leader key ─────────────────────────────────
local act = wezterm.action
-- Leader = Ctrl+Shift+a (same modifier family as the Ctrl+Shift+P palette
-- convention). With Caps Lock → Ctrl (Karabiner), it's pressed Caps+Shift+a.
config.leader = { key = "a", mods = "CTRL|SHIFT", timeout_milliseconds = 1500 }

-- Rename the active tab. Prefilled with the current name; empty input clears the
-- explicit title so the tab goes back to following the pane. Shared by Leader+,
-- and the ⌘P palette entry below.
local set_tab_title = wezterm.action_callback(function(window, _pane, line)
	if line then -- nil when cancelled with Esc
		window:active_tab():set_title(line)
	end
end)

local rename_tab = wezterm.action_callback(function(window, pane)
	window:perform_action(
		act.PromptInputLine({
			description = "New tab name (empty = automatic):",
			initial_value = window:active_tab():get_title(),
			action = set_tab_title,
		}),
		pane
	)
end)

config.keys = {
	-- Shift+Enter → CSI-u "Enter+Shift" (\x1b[13;2u) so apps (claude, nvim) insert a
	-- newline bare AND inside tmux: tmux forwards it through extended-keys (see
	-- tmux.conf). A bare "\n" works bare but doesn't survive tmux's key handling.
	{ key = "Enter", mods = "SHIFT", action = act.SendString("\x1b[13;2u") },

	-- Pass through literal Ctrl+a (SOH) — press the leader combo (Ctrl+Shift+a) twice
	{ key = "a", mods = "LEADER|CTRL|SHIFT", action = act.SendKey({ key = "a", mods = "CTRL" }) },

	-- Splits: create (single-key — visual shape matches the split)
	{ key = "-", mods = "LEADER", action = act.SplitPane({ direction = "Down", size = { Percent = 50 } }) },
	{ key = "|", mods = "LEADER", action = act.SplitPane({ direction = "Right", size = { Percent = 50 } }) },
	{ key = "\\", mods = "LEADER", action = act.SplitPane({ direction = "Right", size = { Percent = 50 } }) },

	-- Splits: nudge resize (Shift+hjkl = "manipulate this pane's geometry")
	{ key = "h", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Left", 5 }) },
	{ key = "j", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Down", 5 }) },
	{ key = "k", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Up", 5 }) },
	{ key = "l", mods = "LEADER|SHIFT", action = act.AdjustPaneSize({ "Right", 5 }) },

	-- Splits: navigate (prefix + hjkl / arrows)
	{ key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
	{ key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
	{ key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
	{ key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
	{ key = "LeftArrow", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
	{ key = "DownArrow", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
	{ key = "UpArrow", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
	{ key = "RightArrow", mods = "LEADER", action = act.ActivatePaneDirection("Right") },
	{ key = "n", mods = "LEADER", action = act.ActivatePaneDirection("Next") },
	{ key = "p", mods = "LEADER", action = act.ActivatePaneDirection("Prev") },

	-- Splits: pane picker overlay
	{ key = "Space", mods = "LEADER", action = act.PaneSelect },

	-- Splits: zoom / swap / rotate / close
	{ key = "f", mods = "LEADER", action = act.TogglePaneZoomState },
	{ key = "=", mods = "LEADER", action = act.PaneSelect({ mode = "SwapWithActive" }) },
	{ key = "o", mods = "LEADER", action = act.RotatePanes("Clockwise") },
	{ key = "q", mods = "LEADER", action = act.CloseCurrentPane({ confirm = false }) },

	-- Splits: resize mode (modal — hjkl/arrows, esc to exit)
	{ key = "r", mods = "LEADER", action = act.ActivateKeyTable({ name = "resize", one_shot = false, timeout_milliseconds = 2000 }) },

	-- Tabs
	{ key = "t", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "[", mods = "LEADER", action = act.ActivateTabRelative(-1) },
	{ key = "]", mods = "LEADER", action = act.ActivateTabRelative(1) },
	{ key = "1", mods = "LEADER", action = act.ActivateTab(0) },
	{ key = "2", mods = "LEADER", action = act.ActivateTab(1) },
	{ key = "3", mods = "LEADER", action = act.ActivateTab(2) },
	{ key = "4", mods = "LEADER", action = act.ActivateTab(3) },
	{ key = "5", mods = "LEADER", action = act.ActivateTab(4) },
	{ key = "6", mods = "LEADER", action = act.ActivateTab(5) },
	{ key = "7", mods = "LEADER", action = act.ActivateTab(6) },
	{ key = "8", mods = "LEADER", action = act.ActivateTab(7) },
	{ key = "9", mods = "LEADER", action = act.ActivateTab(8) },
	{ key = "Tab", mods = "LEADER", action = act.ActivateLastTab },
	{ key = ",", mods = "LEADER", action = rename_tab }, -- tmux's prefix+, (rename-window)

	-- Windows
	{ key = "c", mods = "LEADER|SHIFT", action = act.SpawnWindow },

	-- Scrolling
	{ key = "u", mods = "LEADER", action = act.ScrollByPage(-1) },
	{ key = "d", mods = "LEADER", action = act.ScrollByPage(1) },
	{ key = "g", mods = "LEADER", action = act.ScrollToTop },
	{ key = "g", mods = "LEADER|SHIFT", action = act.ScrollToBottom },

	-- Search scrollback
	{ key = "/", mods = "LEADER", action = act.Search({ CaseSensitiveString = "" }) },

	-- Window fullscreen
	{ key = "f", mods = "LEADER|SHIFT", action = act.ToggleFullScreen },

	-- Command palette: ⌘P. Leader+? kept as an alias; Ctrl+Shift+P (WezTerm
	-- default) still works too. Custom tmux entries are added via
	-- augment-command-palette below.
	{ key = "p", mods = "CMD", action = act.ActivateCommandPalette },
	{ key = "?", mods = "LEADER|SHIFT", action = act.ActivateCommandPalette },

	-- Copy mode / quick select
	{ key = "Enter", mods = "LEADER", action = act.ActivateCopyMode },
	{ key = "s", mods = "LEADER", action = act.QuickSelect },

	-- Copy / paste
	{ key = "y", mods = "LEADER", action = act.CopyTo("ClipboardAndPrimarySelection") },
	{ key = "v", mods = "LEADER", action = act.PasteFrom("Clipboard") },

	-- Font size: use built-in Cmd+= / Cmd+- / Cmd+0 (no leader needed)

	-- Launcher menu (btop, yazi, lazygit, etc.)
	{ key = "m", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "FUZZY|LAUNCH_MENU_ITEMS" }) },

	-- Workspaces
	{ key = "w", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
	{ key = "}", mods = "LEADER", action = act.SwitchWorkspaceRelative(1) },
	{ key = "{", mods = "LEADER", action = act.SwitchWorkspaceRelative(-1) },
	{
		key = "$",
		mods = "LEADER",
		action = act.PromptInputLine({
			description = "Rename workspace:",
			action = wezterm.action_callback(function(window, _pane, line)
				if line and #line > 0 then
					wezterm.mux.rename_workspace(window:active_workspace(), line)
				end
			end),
		}),
	},

	-- Reload config
	{ key = "r", mods = "LEADER|SHIFT", action = act.ReloadConfiguration },
}

config.key_tables = {
	resize = {
		{ key = "h", action = act.AdjustPaneSize({ "Left", 4 }) },
		{ key = "j", action = act.AdjustPaneSize({ "Down", 4 }) },
		{ key = "k", action = act.AdjustPaneSize({ "Up", 4 }) },
		{ key = "l", action = act.AdjustPaneSize({ "Right", 4 }) },
		{ key = "LeftArrow", action = act.AdjustPaneSize({ "Left", 4 }) },
		{ key = "DownArrow", action = act.AdjustPaneSize({ "Down", 4 }) },
		{ key = "UpArrow", action = act.AdjustPaneSize({ "Up", 4 }) },
		{ key = "RightArrow", action = act.AdjustPaneSize({ "Right", 4 }) },
		{ key = "Escape", action = "PopKeyTable" },
		{ key = "Enter", action = "PopKeyTable" },
	},
}

-- ── Status bar (right side) ──────────────────────────────────
-- Shows: [LEADER] · workspace · key-table · time
config.status_update_interval = 1000

wezterm.on("update-right-status", function(window, _pane)
	local segments = {}
	local palette = window:effective_config().resolved_palette
	local t = theme_for_appearance(window:get_appearance())

	-- Leader indicator (Catppuccin red on base)
	if window:leader_is_active() then
		table.insert(segments, { bg = t.leader_bg, fg = t.leader_fg, text = " LEADER " })
	end

	-- Active key table (Catppuccin yellow on base)
	local kt = window:active_key_table()
	if kt then
		table.insert(segments, { bg = t.ktable_bg, fg = t.ktable_fg, text = " " .. kt:upper() .. " " })
	end

	-- Workspace
	table.insert(segments, {
		bg = palette.tab_bar and palette.tab_bar.active_tab.bg_color or t.active_bg,
		fg = palette.foreground or t.active_fg,
		text = " " .. window:active_workspace() .. " ",
	})

	local elements = {}
	for _, seg in ipairs(segments) do
		table.insert(elements, { Background = { Color = seg.bg } })
		table.insert(elements, { Foreground = { Color = seg.fg } })
		table.insert(elements, { Attribute = { Intensity = "Bold" } })
		table.insert(elements, { Text = seg.text })
	end
	table.insert(elements, "ResetAttributes")

	window:set_right_status(wezterm.format(elements))
end)

-- ── Command-palette: tmux control (⌘P) ───────────────────────────────────────
-- One tmux session per WezTerm tab, so the palette drives tmux per-tab: switch
-- to a session (by activating the tab already attached to it), and rename the
-- session/window living in this tab. (No keystroke injection — sending the
-- prefix + ":switch-client" races with the InputSelector overlay tearing down,
-- so the leading bytes get dropped and the rest leaks to the shell.)
--
-- Which tmux client belongs to a tab is resolved via the pane's tty, which IS
-- the client tty. The reverse direction can't be trusted: `wezterm cli` inside
-- tmux reads $WEZTERM_PANE from the tmux server's inherited environment, so
-- every pane claims to be whichever tab the server was started in.
--
-- Why one entry + InputSelector (not one palette entry per session): in this
-- WezTerm, wezterm.run_child_process YIELDS, so it only runs inside a coroutine.
-- The augment-command-palette hook runs OUTSIDE one (it must return entries
-- synchronously), so shelling out there throws "attempt to yield from outside a
-- coroutine" and the palette comes up empty. An action_callback DOES run in a
-- coroutine, so the `tmux list-sessions` call is deferred to selection time.
local tmux_bin = (function()
	-- GUI apps launched by launchd have a minimal PATH and often no $USER, so
	-- derive the user from $HOME (reliably set) and try absolute paths first. No
	-- run_child_process here: config eval isn't a coroutine, so it can't yield.
	local home = wezterm.home_dir or os.getenv("HOME") or ""
	local user = home:match("([^/]+)/?$") or "" -- nix-darwin: /etc/profiles/per-user/<user>
	for _, p in ipairs({
		"/etc/profiles/per-user/" .. user .. "/bin/tmux",
		home .. "/.nix-profile/bin/tmux",
		"/run/current-system/sw/bin/tmux",
		"/opt/homebrew/bin/tmux",
		"/usr/local/bin/tmux",
	}) do
		local fh = io.open(p, "r")
		if fh then
			fh:close()
			return p
		end
	end
	return "tmux" -- fall back to PATH (works when WezTerm is launched from a shell)
end)()

-- The tty of the tmux client living in the active tab, or nil. Two traps this
-- deliberately avoids:
--   • the pane handed to a palette entry or prompt callback is a GUI *overlay*
--     pane ("not visible to the mux layer" per the docs), not the tmux one — so
--     the panes come from the mux tab instead, same as the tab rename above;
--   • `tmux display-message -c <tty>` does NOT fail on a tty that isn't a
--     client: it silently answers for tmux's current client. Renaming off that
--     answer hits whatever session that client happens to be on, so the tty is
--     matched against list-clients first and we bail rather than guess.
local function tmux_client_tty(window)
	local ok, out = wezterm.run_child_process({ tmux_bin, "list-clients", "-F", "#{client_tty}" })
	if not ok or not out then
		return nil
	end
	local clients = {}
	for line in out:gmatch("[^\r\n]+") do
		clients[line] = true
	end
	for _, p in ipairs(window:active_tab():panes()) do
		local tty = p:get_tty_name()
		if tty and clients[tty] then
			return tty
		end
	end
	return nil
end

-- Ask tmux about that client: `-c <tty>` targets it, so the answer is about the
-- tab you're looking at. Only ever called with a tty verified above.
local function tmux_query(tty, format)
	if not tty then
		return nil
	end
	local ok, out = wezterm.run_child_process({ tmux_bin, "display-message", "-p", "-c", tty, format })
	if not ok or not out then
		return nil
	end
	local value = out:gsub("%s+$", "")
	return value ~= "" and value or nil
end

-- The prompt overlay is modal, so a single pending target + one hoisted callback
-- is enough (wezterm.action_callback registers an event handler per call — a
-- fresh one per invocation would accumulate handlers for the life of the GUI).
local pending_rename

local apply_tmux_rename = wezterm.action_callback(function(_window, _pane, line)
	local p = pending_rename
	pending_rename = nil
	if p and line and #line > 0 then
		wezterm.run_child_process({ tmux_bin, p.cmd, "-t", p.target, line })
	end
end)

-- kind = "session" | "window": prompt (prefilled) and rename whichever one this
-- tab's tmux client currently has.
local function tmux_rename_action(kind)
	local name_format = kind == "session" and "#S" or "#W"
	local target_format = kind == "session" and "#S" or "#S:#I"
	return wezterm.action_callback(function(window, pane)
		local tty = tmux_client_tty(window)
		local target = tty and tmux_query(tty, target_format)
		if not target then
			window:toast_notification("wezterm", "No tmux client attached in this tab", nil, 4000)
			return
		end
		pending_rename = { cmd = "rename-" .. kind, target = target }
		window:perform_action(
			act.PromptInputLine({
				description = "New tmux " .. kind .. " name:",
				initial_value = tmux_query(tty, name_format) or "",
				action = apply_tmux_rename,
			}),
			pane
		)
	end)
end

local rename_tmux_session = tmux_rename_action("session")
local rename_tmux_window = tmux_rename_action("window")

-- session name → the tab it's attached to, matched on tty (client ↔ pane).
local function tabs_by_session()
	local ok, out = wezterm.run_child_process({
		tmux_bin, "list-clients", "-F", "#{client_tty}\t#{session_name}",
	})
	local session_of_tty = {}
	if ok and out then
		for line in out:gmatch("[^\r\n]+") do
			local tty, session = line:match("^(.-)\t(.+)$")
			if tty then
				session_of_tty[tty] = session
			end
		end
	end
	local found = {}
	for _, mux_window in ipairs(wezterm.mux.all_windows()) do
		for _, tab in ipairs(mux_window:tabs()) do
			for _, p in ipairs(tab:panes()) do
				local session = session_of_tty[p:get_tty_name() or ""]
				if session then
					found[session] = { tab = tab, window = mux_window }
				end
			end
		end
	end
	return found
end

-- Activate the tab that session is already attached to; only a detached session
-- gets a new tab. Deliberately NOT switch-client: that would point a second tab
-- at the same session, and tmux then shrinks both clients to the smaller size.
local activate_session = wezterm.action_callback(function(window, _pane, id)
	if not id then -- nil when cancelled
		return
	end
	local found = tabs_by_session()[id]
	if found then
		found.tab:activate()
		local gui = found.window:gui_window()
		if gui then
			gui:focus()
		end
	else
		window:mux_window():spawn_tab({ args = { tmux_bin, "attach-session", "-t", id } })
	end
end)

-- Live tmux sessions as InputSelector choices (must be called from a coroutine).
local function tmux_session_choices()
	local ok, out = wezterm.run_child_process({
		tmux_bin, "list-sessions", "-F", "#{session_name}\t#{session_windows}\t#{?session_attached,1,0}",
	})
	local choices = {}
	if ok and out then
		for line in out:gmatch("[^\r\n]+") do
			local name, wins, attached = line:match("^(.-)\t(%d+)\t(%d)$")
			if name then
				local label = name .. "  · " .. wins .. (wins == "1" and " win" or " wins")
				if attached == "1" then
					label = label .. "  (attached)"
				end
				table.insert(choices, { id = name, label = label })
			end
		end
	end
	return choices
end

local switch_session = wezterm.action_callback(function(window, pane)
	local choices = tmux_session_choices()
	if #choices == 0 then
		window:toast_notification("wezterm", "No tmux sessions found (tmux not running?)", nil, 4000)
		return
	end
	window:perform_action(
		act.InputSelector({
			title = "tmux sessions",
			fuzzy = true,
			fuzzy_description = "switch to session: ",
			choices = choices,
			action = activate_session,
		}),
		pane
	)
end)

wezterm.on("augment-command-palette", function(_window, _pane)
	return {
		{
			brief = "tab: rename…",
			icon = "md_rename_box",
			action = rename_tab,
		},
		{
			brief = "tmux: switch session…",
			action = switch_session,
		},
		{
			brief = "tmux: rename session…",
			icon = "md_rename_box",
			action = rename_tmux_session,
		},
		{
			brief = "tmux: rename window…",
			icon = "md_rename_box",
			action = rename_tmux_window,
		},
	}
end)

return config
