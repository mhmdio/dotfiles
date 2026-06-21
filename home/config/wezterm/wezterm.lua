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
	cfg.command_palette_bg_color = t.palette_bg
	cfg.command_palette_fg_color = t.palette_fg
end

-- Font
config.font = wezterm.font("Maple Mono NF", { weight = "Bold" })
config.font_size = 16
config.harfbuzz_features = { "calt=1", "clig=1", "liga=1" }
config.freetype_load_target = "Light"

-- Window
config.window_background_opacity = 0.90
config.macos_window_background_blur = 20
config.window_decorations = "RESIZE"
-- small padding so text doesn't butt against the window edge / blur
config.window_padding = { left = 10, right = 10, top = 8, bottom = 8 }
config.window_close_confirmation = "NeverPrompt"
config.adjust_window_size_when_changing_font_size = false

-- Bell
config.audible_bell = "Disabled"
config.visual_bell = {
	fade_in_function = "EaseIn",
	fade_in_duration_ms = 150,
	fade_out_function = "EaseOut",
	fade_out_duration_ms = 150,
}
config.colors = { visual_bell = "#202020" }

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
config.force_reverse_video_cursor = true

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

-- Launcher entries (Meh+a → m)
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

-- ── Leader key ─────────────────────────────────
local act = wezterm.action
-- Leader = Ctrl+Alt+a. With Caps Lock → Ctrl (Karabiner), it's pressed Caps+Opt+a.
config.leader = { key = "a", mods = "CTRL|ALT", timeout_milliseconds = 1500 }

config.keys = {
	-- Shift+Enter sends literal newline
	{ key = "Enter", mods = "SHIFT", action = act.SendString("\n") },

	-- Pass through literal Ctrl+a (SOH) — press Meh+a twice
	{ key = "a", mods = "LEADER|CTRL|ALT", action = act.SendKey({ key = "a", mods = "CTRL" }) },

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

	-- Splits: zoom / equalize / rotate / close
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

	-- Command palette: ⌘⌥P (the common modifier+P convention). Leader+? kept as the
	-- in-terminal help-style alias.
	{ key = "p", mods = "CMD|ALT", action = act.ActivateCommandPalette },
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

	-- Leader indicator (Catppuccin red on base)
	if window:leader_is_active() then
		table.insert(segments, { bg = "#f38ba8", fg = "#1e1e2e", text = " LEADER " })
	end

	-- Active key table (Catppuccin yellow on base)
	local kt = window:active_key_table()
	if kt then
		table.insert(segments, { bg = "#f9e2af", fg = "#1e1e2e", text = " " .. kt:upper() .. " " })
	end

	-- Workspace
	table.insert(segments, {
		bg = palette.tab_bar and palette.tab_bar.active_tab.bg_color or "#1e1e2e",
		fg = palette.foreground or "#cdd6f4",
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

return config
