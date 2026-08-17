local wezterm = require("wezterm")
local config = wezterm.config_builder()

-- Catppuccin palettes — the single source of truth all tools follow.
local themes = {
	dark = {
		color_scheme = "Catppuccin Mocha",
		-- Three levels, and they have to be three: bar < inactive tab < active tab.
		-- The bar used to be mantle, the same value as an inactive tab, so an
		-- unfocused tab had no edge at all — a run of grey text with nothing under
		-- it reading as a tab. Crust puts the bar behind them, mantle raises the
		-- tabs onto it, and base makes the active one continuous with the terminal.
		frame_bg = "#11111b", -- crust: the bar itself
		frame_fg = "#cdd6f4",
		active_bg = "#1e1e2e", -- base: same as the terminal below it
		active_fg = "#cdd6f4",
		inactive_bg = "#181825", -- mantle: raised off the bar, below the active tab
		inactive_fg = "#45475a",
		hover_bg = "#313244",
		hover_fg = "#cdd6f4",
		new_tab_bg = "#11111b",
		new_tab_fg = "#89b4fa",
		new_tab_hover_bg = "#313244",
		palette_bg = "#1e1e2e",
		palette_fg = "#cdd6f4",
		bell = "#313244", -- surface0: a flash, not a blackout
		leader_bg = "#f38ba8", -- status badges (red / yellow on base)
		leader_fg = "#1e1e2e",
		ktable_bg = "#f9e2af",
		ktable_fg = "#1e1e2e",
		accent = "#89b4fa", -- ANSI blue — the slot tmux's bar borrows, so both match
		split = "#45475a", -- surface1: pane divider
		-- Inactive panes dim (tmux has no equivalent, so it only ever helps).
		-- Dark can take a real knock; Latte is already near-white, where the same
		-- multiplier reads as a grey shadow rather than "unfocused".
		hsb = { saturation = 0.9, brightness = 0.72 },
	},
	light = {
		color_scheme = "Catppuccin Latte",
		frame_bg = "#dce0e8", -- crust
		frame_fg = "#4c4f69",
		active_bg = "#eff1f5", -- base
		active_fg = "#4c4f69",
		inactive_bg = "#e6e9ef", -- mantle
		inactive_fg = "#9ca0b0", -- overlay0: Latte's surface1 was too faint to read
		hover_bg = "#ccd0da",
		hover_fg = "#4c4f69",
		new_tab_bg = "#dce0e8",
		new_tab_fg = "#1e66f5",
		new_tab_hover_bg = "#ccd0da",
		palette_bg = "#eff1f5",
		palette_fg = "#4c4f69",
		bell = "#ccd0da",
		leader_bg = "#d20f39",
		leader_fg = "#eff1f5",
		ktable_bg = "#df8e1d",
		ktable_fg = "#4c4f69", -- dark on Latte's gold; white washes out
		accent = "#1e66f5",
		split = "#bcc0cc",
		hsb = { saturation = 0.92, brightness = 0.95 },
	},
}

local function theme_for_appearance(appearance)
	if appearance:find("Dark") then
		return themes.dark
	else
		return themes.light
	end
end

-- wezterm.gui resolves to nil outside the GUI process (documented), and the mux
-- server evaluates this same file whenever a unix domain is attached — see the
-- domains block below. An unguarded get_appearance() there is a config-load error,
-- which is a spawn failure, not a cosmetic one.
local function appearance()
	local gui = wezterm.gui
	return (gui and gui.get_appearance()) or "Dark"
end

local function exists(path)
	local fh = io.open(path, "r")
	if fh then
		fh:close()
		return true
	end
	return false
end

-- Absolute path to a CLI, or its bare name as a last resort. Every helper that
-- shells out goes through this: a GUI launched by launchd inherits a minimal PATH
-- and often no $USER, so a bare "zoxide" resolves only when WezTerm happens to
-- have been started from a shell. $HOME is reliably set, so the nix-darwin
-- per-user profile is derived from it. No run_child_process to find them — config
-- eval isn't a coroutine, so it can't yield.
local function find_bin(name)
	local home = wezterm.home_dir or os.getenv("HOME") or ""
	local user = home:match("([^/]+)/?$") or ""
	for _, dir in ipairs({
		"/etc/profiles/per-user/" .. user .. "/bin",
		home .. "/.nix-profile/bin",
		"/run/current-system/sw/bin",
		"/opt/homebrew/bin",
		"/usr/local/bin",
		"/usr/bin",
	}) do
		local p = dir .. "/" .. name
		if exists(p) then
			return p
		end
	end
	return name
end

local function apply_theme(cfg, t)
	cfg.color_scheme = t.color_scheme
	cfg.window_frame = {
		font = wezterm.font({ family = "Maple Mono NF", weight = "Bold" }),
		-- Inert while use_fancy_tab_bar is false, and kept only so flipping that
		-- back needs no other edit. Verified in the source: window_frame is read by
		-- render/fancy_tab_bar.rs (titlebar bg) and render/borders.rs (border
		-- colours, unset here) — the retro bar reads neither, so this sizes nothing
		-- today. The tab bar's only size lever is config.font_size; see below.
		font_size = 18,
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
	cfg.colors.split = t.split
	cfg.inactive_pane_hsb = t.hsb
	cfg.command_palette_bg_color = t.palette_bg
	cfg.command_palette_fg_color = t.palette_fg
end

-- Font (Regular as the default weight so bold renders as actual emphasis; the
-- tab-bar/window-frame stays Bold below)
config.font = wezterm.font("Maple Mono NF")
config.font_size = 16
config.harfbuzz_features = { "calt=1", "clig=1", "liga=1" }
config.freetype_load_target = "Light"

-- Window. Opaque, which is WezTerm's default, so nothing is set here. The glass
-- (0.90 dark / 0.96 light + a 20px blur) had to go: nvim's colorscheme paints
-- Normal, and text_background_opacity is 1.0, so the editor drew fully opaque
-- inside a translucent window — a hard step under the tmux bar and a lit frame
-- down the other three sides. Translucency is all-or-nothing here, and "all"
-- costs nvim its layering (see nvim/lua/plugins/colorscheme.lua).
config.window_decorations = "RESIZE"
-- small padding so text doesn't butt against the window edge
config.window_padding = { left = 10, right = 10, top = 8, bottom = 8 }
config.window_close_confirmation = "NeverPrompt"
config.adjust_window_size_when_changing_font_size = false
-- Snap drag-resize to whole cells. Off by default, so any drag leaves up to one
-- row of slack the grid can't use — WezTerm parks it under the last row and
-- fills it with the background. Invisible at a shell prompt, obvious in nvim or
-- yazi, which paint that last row: measured 25px of it below the statusline,
-- three times the padding above. Only governs interactive resizes — maximise or
-- a tiling manager hands over whatever height it likes and the slack returns.
config.use_resize_increments = true

-- Bell (flash colour is themed — see apply_theme; a fixed dark grey flashed
-- near-black on Latte, and the appearance-switch override dropped it entirely)
config.audible_bell = "Disabled"
config.visual_bell = {
	fade_in_function = "EaseIn",
	fade_in_duration_ms = 150,
	fade_out_function = "EaseOut",
	fade_out_duration_ms = 150,
}

-- Tabs. The retro bar, not the fancy one: only retro renders as terminal cells,
-- which is what makes the powerline wedges below possible. The cost is fixed and
-- worth knowing — per the docs the retro bar "is rendered using the main terminal
-- font", so it is 16pt like the body and window_frame.font_size no longer reaches
-- it. There is no separate size knob; the only lever is config.font_size itself.
config.use_fancy_tab_bar = false
config.tab_max_width = 32
-- Was true, which silently took the whole status bar with it. The status lines are
-- not a separate surface: tabbar.rs composes left_status and right_status INTO the
-- tab bar line, and render/paint.rs gates the entire thing behind one
-- `if self.show_tab_bar` — which mod.rs recomputes as
-- `num_tabs == 1 && hide_tab_bar_if_only_one_tab` → false. So with a single tab the
-- workspace pill, the leader indicator and the whole CPU/RAM/disk/battery/clock row
-- were simply not painted, which is most of a session. Set this back to true only
-- if a bare single-tab window is worth more than the bar.
config.hide_tab_bar_if_only_one_tab = false
config.show_new_tab_button_in_tab_bar = true
config.switch_to_last_active_tab_when_closing_tab = true
config.tab_and_split_indices_are_zero_based = false

-- ── Glyphs ───────────────────────────────────────────────────────────────────
-- Written as \u{...} escapes, never as literal characters, and this is not
-- fussiness: these are Private Use Area codepoints and they do NOT survive every
-- tool that rewrites this file. Measured — every 3-byte BMP glyph in this table
-- had been silently emptied to "" while the 4-byte ones came through, so most
-- tabs rendered with no icon at all. tmux.conf's @icon records hitting exactly
-- the same trap ("strip them and every rule quietly becomes s/x//"). Escapes are
-- plain ASCII on disk, so there is nothing left to strip.
--
-- Codepoints are lifted from tmux.conf's @icon table so a process wears the same
-- icon in both bars. All 27 verified present in Maple Mono NF.
local G = {
	nvim = "\u{e62b}",
	git = "\u{e702}",
	files = "\u{f07c}",
	claude = "\u{f06a9}",
	node = "\u{e718}",
	python = "\u{e73c}",
	infra = "\u{f01a7}",
	ssh = "\u{f0318}",
	monitor = "\u{f42b}",
	shell = "\u{f489}",
	dot = "\u{ebe3}", -- @icon's outermost catch-all
	zoom = "\u{f4a7}",
	wedge = "\u{e0b0}", -- solid powerline hand-off
	session = "\u{ebc8}", -- workspace pill, idle
	bolt = "\u{f0e7}", -- workspace pill, leader armed
	cpu = "\u{f2db}",
	ram = "\u{f233}",
	disk = "\u{eb4b}",
	clock = "\u{f017}",
	calendar = "\u{f073}",
	battery = { "\u{f244}", "\u{f243}", "\u{f242}", "\u{f241}", "\u{f240}" }, -- empty→full
}

local icons = {}
for _, spec in ipairs({
	{ G.nvim, "nvim", "vim" },
	{ G.git, "git", "lazygit", "gh", "tig" },
	{ G.files, "yazi", "ranger", "lf", "nnn" },
	{ G.claude, "claude" },
	{ G.node, "node", "npm", "pnpm", "yarn", "bun", "deno" },
	{ G.python, "python", "python3", "uv", "ipython", "pytest" },
	{ G.infra, "docker", "docker-compose", "kubectl", "k9s", "terraform", "tofu" },
	{ G.ssh, "ssh", "mosh" },
	{ G.monitor, "btop", "htop", "top", "glances" },
	{ G.shell, "zsh", "bash", "fish", "sh", "tmux" },
}) do
	for i = 2, #spec do
		icons[spec[i]] = spec[1]
	end
end

local function icon_for(name)
	return icons[name] or G.dot
end

-- The theme in force, cached. format-tab-title runs for every tab on every tab
-- bar repaint, and get_appearance() is a call into AppKit — not something to do
-- per tab at 120fps. Kept current by window-config-reloaded, which is already
-- the one place that notices the appearance moving.
local active_theme = theme_for_appearance(appearance())

-- Foreground process, keyed by pane id, refreshed on the status timer below.
-- The docs put foreground_process_name on the computed-on-access side of
-- PaneInformation and warn that reading it "may not be cheap to compute" —
-- format-tab-title runs for every tab on every repaint, which is exactly the
-- wrong place to pay that. update-status runs once a second, which is plenty for
-- a value that only changes when you launch something. Rebuilt each tick rather
-- than updated in place, so panes that close drop out instead of accumulating.
local pane_prog = {}

wezterm.on("format-tab-title", function(tab, tabs, _panes, _cfg, hover, max_width)
	local t = active_theme
	local pane = tab.active_pane

	-- What the tab RUNS. Three sources, cheapest first. WEZTERM_PROG is the shell
	-- integration's OSC 1337 and is pre-computed, but it only exists once that
	-- integration is actually loaded and it does not survive tmux, so it is empty
	-- more often than not. pane_prog covers everything else. The title is a last
	-- resort, and is empty for anything that doesn't set one.
	local prog = ((pane.user_vars or {}).WEZTERM_PROG or ""):match("^%S*") or ""
	if prog == "" then
		prog = pane_prog[pane.pane_id] or ""
	end
	if prog == "" then
		prog = (pane.title or ""):match("^%S*") or ""
	end
	-- claude reports its version as the process name, so a bare pane running it
	-- comes back as "2.1.220" — the rename tmux's automatic-rename-format does,
	-- done here for the tmux-less case.
	if prog:match("^[0-9][0-9.]*$") then
		prog = "claude"
	end

	-- What the tab SAYS, which is a different question: an app is free to set its
	-- own title (claude writes a progress line into it). An app that sets NO title
	-- is the case this used to miss — nvim leaves 'title' off by default, so its
	-- pane title is the empty string, and the tab rendered as a bare index with no
	-- name and no icon at all. Fall back to whatever the pane is running.
	local title = tab.tab_title
	if not title or #title == 0 then
		title = pane.title or ""
		if #title == 0 then
			title = prog
		end
		if title:match("^[0-9][0-9.]*$") then
			title = "claude"
		end
	end

	-- A title starting outside ASCII is already icon-prefixed — that's tmux's
	-- set-titles-string ("#{E:@icon} #S"). Stacking ours on top gave every tmux tab
	-- two glyphs, so trust whoever got there first. An EMPTY title has no first
	-- byte, and the old `title:byte(1) and …` form read that as "already prefixed"
	-- and dropped the icon — the other half of the blank nvim tab.
	local prefix = ""
	local first = title:byte(1)
	if first == nil or first < 0xEE then
		prefix = icon_for(prog) .. " "
	end

	local flags = ""
	if pane.is_zoomed then
		flags = flags .. " " .. G.zoom
	end
	-- tmux's activity flag: something printed in a tab you aren't looking at.
	if not tab.is_active and pane.has_unseen_output then
		flags = flags .. " ●"
	end

	local index = tostring(tab.tab_index + 1)
	-- Two spaces of padding either side, not one: the bar can't grow its font (it
	-- is the terminal's), so width is the only dimension left to give the tabs any
	-- presence. Budget the truncation against it — column_width, not #, because a
	-- Nerd Font glyph is 3-4 bytes and draws in one or two cells.
	local room = max_width - (#index + wezterm.column_width(prefix .. flags) + 7)
	if room < 4 then
		room = 4
	end
	title = wezterm.truncate_right(title, room)

	-- Each tab paints its own slab and then the wedge that hands over to the NEXT
	-- tab's colour, so the run is continuous with no gaps; the last hands over to
	-- the bar. Getting the wedge's two colours backwards is the classic powerline
	-- mistake — it is drawn in THIS tab's background over the next one's.
	local bg = tab.is_active and t.accent or t.inactive_bg
	local fg = tab.is_active and t.frame_bg or (hover and t.hover_fg or t.inactive_fg)
	local next_bg = t.frame_bg
	for _, other in ipairs(tabs) do
		if other.tab_index == tab.tab_index + 1 then
			next_bg = other.is_active and t.accent or t.inactive_bg
		end
	end
	return {
		{ Background = { Color = bg } },
		{ Foreground = { Color = fg } },
		{ Attribute = { Intensity = tab.is_active and "Bold" or "Normal" } },
		{ Text = "  " .. index .. " " .. prefix .. title .. flags .. "  " },
		{ Background = { Color = next_bg } },
		{ Foreground = { Color = bg } },
		{ Text = G.wedge },
	}
end)

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

-- Quick select (Leader+s): these ADD to the built-ins (URLs, paths, sha1-ish
-- hex), they don't replace them — disable_default_quick_select_patterns would.
-- Rust regex, NOT Lua patterns: %d and %s here match a literal % followed by a
-- letter, so the rule silently never fires. Backslashes are doubled for Lua.
config.quick_select_patterns = {
	"[^\\s:]+\\.[a-zA-Z]+:\\d+(:\\d+)?", -- file.ext:line[:col] — compiler/test output
	"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}", -- uuid
	"\\b(?:\\d{1,3}\\.){3}\\d{1,3}\\b", -- ipv4
	"[a-zA-Z0-9._/-]+@sha256:[0-9a-f]{7,64}", -- pinned container image
}

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

-- Tell tmux the appearance flipped. WezTerm doesn't implement DEC mode 2031 —
-- the terminal→app "theme changed" report (wezterm#6454) — so a tmux client goes
-- on answering OSC 11 with the background it cached when it attached. Measured:
-- a session attached in dark still reported #1e1e2e long after the switch, so
-- every nvim opened inside it loaded Mocha onto a Latte terminal, and restarting
-- nvim couldn't help — the stale value lives in tmux, not in the editor.
--
-- tmux itself understands 2031 (it answers `CSI ?2031;2$y`) and nvim enables the
-- mode when it sees that, so synthesising the report here flips even a RUNNING
-- editor: tmux re-reads the background and nvim fires OptionSet. Only panes whose
-- foreground process is tmux get it — anywhere else the escape would land in the
-- program's stdin as literal keystrokes.
-- Panes hang off tabs, not off the window: MuxWindow has tabs()/active_tab() but
-- no panes(). Calling it threw "attempt to call a nil value (method 'panes')" on
-- every appearance flip, which aborted this function before a single report went
-- out — the colours still changed (set_config_overrides runs first) while tmux
-- and nvim were never told, i.e. exactly the bug this is here to fix.
local function notify_theme_change(window, appearance)
	local report = appearance:find("Dark") and "\27[?997;1n" or "\27[?997;2n"
	for _, tab in ipairs(window:mux_window():tabs()) do
		for _, pane in ipairs(tab:panes()) do
			local proc = pane:get_foreground_process_name()
			if proc and proc:match("[^/]+$"):match("^tmux") then
				pane:send_text(report)
			end
		end
	end
end

-- Apply themed tab bar + scheme based on macOS appearance
apply_theme(config, theme_for_appearance(appearance()))

-- Which appearance each window has already reported, so a plain config reload
-- (Leader+R, or the file changing) doesn't re-announce a theme that never moved.
local reported = {}

-- The report has to go out on the SECOND pass through this handler. Reporting
-- straight after set_config_overrides looks right and is a race: the Lua config
-- updates synchronously — effective_config() returns the new scheme immediately —
-- but the terminal keeps answering OSC 11 with the OLD background for a beat, and
-- tmux answers a 2031 report by RE-QUERYING OSC 11 rather than trusting the bit
-- in it (both measured). So tmux read the previous background and every switch
-- handed nvim the previous theme: turn dark mode on and the editor stayed light.
-- Measured over four runs each: reporting immediately was stale 3/4 times,
-- reporting on the refired pass 0/4. set_config_overrides re-emits this event by
-- design (documented), so that second pass is free and deterministic.
-- Every scalar apply_theme owns. Overrides SHADOW the base config, so gating the
-- re-apply on color_scheme alone froze all the others: edit the tab-bar font size
-- or a frame colour and windows kept the values they were given at startup until
-- the next appearance flip. Comparing the whole set fixes that, and stays
-- loop-safe because apply_theme is deterministic — one pass and the signatures
-- match. Fonts are excluded on purpose: wezterm.font returns an object that need
-- not compare equal to itself, which would re-fire forever.
local function theme_sig(cfg)
	local wf = cfg.window_frame or {}
	local tb = (cfg.colors or {}).tab_bar or {}
	return table.concat({
		tostring(cfg.color_scheme),
		tostring(wf.font_size),
		tostring(wf.active_titlebar_bg),
		tostring(tb.background),
		tostring(cfg.command_palette_bg_color),
		tostring((cfg.colors or {}).split),
		tostring((cfg.inactive_pane_hsb or {}).brightness),
	}, "|")
end

wezterm.on("window-config-reloaded", function(window, _)
	local overrides = window:get_config_overrides() or {}
	local appearance = window:get_appearance()
	local target = theme_for_appearance(appearance)
	active_theme = target -- what the tab bar paints with; see the note by icon_for
	local desired = {}
	apply_theme(desired, target)
	if theme_sig(overrides) ~= theme_sig(desired) then
		apply_theme(overrides, target)
		window:set_config_overrides(overrides)
		return -- re-fires this handler; the colours are live on that pass
	end
	local id = window:mux_window():window_id()
	if reported[id] ~= appearance then
		reported[id] = appearance
		notify_theme_change(window, appearance)
	end
end)

-- Name the default workspace "WezTerm" (instead of "default") — shows in the
-- left status bar and the Leader+w workspace switcher.
config.default_workspace = "WezTerm"

-- ── Persistence: the one thing WezTerm needs a domain for ────────────────────
-- Panes in the local domain die with the GUI. A unix domain moves them into a
-- wezterm-mux-server that outlives it, which is WezTerm's own detach/attach:
-- ⌘P "domain: attach…" puts a tab in it, Leader+Shift+D detaches, and whatever
-- was running is still there after a restart.
--
-- Deliberately NOT auto-connected (no default_gui_startup_args = {"connect",…}).
-- Process introspection is documented as local-panes-only: over ANY multiplexer
-- domain, unix included, pane:get_foreground_process_name() returns nil. Three
-- things here run on it — the tmux theme-change bridge below, the tab-title
-- icons, and Ctrl+hjkl passthrough — so making every pane a mux pane by default
-- would trade a working theme switch for persistence tmux already provides.
--
-- Attaching per-tab keeps both: ordinary tabs stay local and fully introspected,
-- and anything that has to survive a restart is opted in one tab at a time. The
-- mux server pins the wezterm binary it started with, so after a nix switch that
-- bumps wezterm a reattach can fail on a version mismatch; `pkill
-- wezterm-mux-server` clears it (and takes the persisted panes with it).
config.unix_domains = { { name = "persist" } }

-- ── Leader key ───────────────────────────────────────────────────────────────
local act = wezterm.action
-- Leader = ⌘a: one modifier, thumb and pinky, no three-key stretch.
--
-- The reason it's Cmd and not Ctrl is that macOS never delivers a Cmd chord to
-- the program running inside the terminal, so this leader takes NOTHING away
-- from tmux, nvim, zsh or claude. A Ctrl leader always costs something: Ctrl+a
-- is beginning-of-line (bound in zoptions.zsh) and Ctrl+Space opens blink.cmp's
-- completion menu, and WezTerm would swallow either before the app saw it. That
-- also retires the old double-tap binding that existed only to hand a literal
-- Ctrl+a back. WezTerm builds no macOS menu bar, so nothing claims ⌘A first.
--
-- Linux has no equally free modifier — Super belongs to the window manager — so
-- it falls back to Ctrl+;, which has no terminal encoding at all and is
-- therefore just as free of app conflicts.
local is_mac = wezterm.target_triple:find("darwin") ~= nil
config.leader = is_mac and { key = "a", mods = "CMD", timeout_milliseconds = 1500 }
	or { key = ";", mods = "CTRL", timeout_milliseconds = 1500 }

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

-- ── Ctrl+hjkl: one motion for nvim splits, tmux panes and WezTerm panes ──────
-- vim-tmux-navigator already joins nvim↔tmux inside a pane; this carries the same
-- keys outward, so a WezTerm split is crossed with the motion you already use.
-- Anything that manages its own splits gets the key untouched — otherwise the
-- editor would lose Ctrl+h/j/k/l the moment it stopped being alone on screen.
--
-- A single-pane tab always passes through: there is nowhere to move, and Ctrl+l
-- is the shell's clear-screen. Mux panes report no process name (see the domains
-- block), which lands in that same pass-through branch — the safe direction.
local function nav(key, dir)
	return wezterm.action_callback(function(window, pane)
		-- The tab's panes, not pane:tab(): a callback can be handed a GUI overlay
		-- pane, which the mux layer doesn't know about (same trap as rename_tab).
		local panes = window:active_tab():panes()
		local proc = pane:get_foreground_process_name()
		proc = proc and proc:match("[^/]+$") or ""
		if #panes < 2 or proc:match("^n?vim$") or proc:match("^tmux") then
			window:perform_action(act.SendKey({ key = key, mods = "CTRL" }), pane)
		else
			window:perform_action(act.ActivatePaneDirection(dir), pane)
		end
	end)
end

-- ── Sessionizer: project → workspace (Leader+f) ──────────────────────────────
-- The WezTerm-level twin of tmux's prefix+f. Workspaces are WezTerm's sessions,
-- so picking a project either jumps to its live workspace or spawns one rooted in
-- its directory. Two sources: zoxide, which orders the list by what you actually
-- use, and every git checkout under ~/Developer, so a fresh clone is offerable
-- before it has been visited once.
--
-- Both shell out, and run_child_process yields — legal only inside a coroutine.
-- action_callback runs in one; config file scope does not (same constraint the
-- tmux palette entries are built around).
local PROJECTS = (wezterm.home_dir or os.getenv("HOME") or "") .. "/Developer"
local zoxide_bin = find_bin("zoxide")
local fd_bin = find_bin("fd")

-- stdout, or nil. run_child_process RAISES when the binary can't be spawned
-- rather than returning false, so an uninstalled zoxide would take the whole
-- picker down instead of just contributing nothing to it.
local function capture(argv)
	local called, ok, out = pcall(wezterm.run_child_process, argv)
	if called and ok and type(out) == "string" then
		return out
	end
	return nil
end

local function project_dirs()
	local seen, dirs = {}, {}
	local function add(dir)
		if dir and #dir > 1 and not seen[dir] and exists(dir) then
			seen[dir] = true
			table.insert(dirs, dir)
		end
	end

	-- zoxide first: its order IS the ranking, so the top of the list is the work in
	-- flight. Its entries outlive a deleted checkout, hence the exists() gate.
	local out = capture({ zoxide_bin, "query", "-l" })
	if out then
		for line in out:gmatch("[^\r\n]+") do
			add(line)
		end
	end

	-- --prune keeps fd out of the .git it just matched. Depth 4 is exactly
	-- ~/Developer/<area>/<org>/<repo>/.git — the layout in use, and ~5x faster
	-- than 5 (measured 0.13s vs 0.44s over ~400 repos) for 38 nested ones missed.
	out = capture({
		fd_bin,
		"--hidden",
		"--no-ignore",
		"--prune",
		"--max-depth",
		"4",
		"--type",
		"d",
		"--glob",
		".git",
		PROJECTS,
	})
	if out then
		for line in out:gmatch("[^\r\n]+") do
			add((line:gsub("/%.git/?$", "")))
		end
	end
	return dirs
end

-- tmux-sessionizer's naming rule, so a project answers to the same name in both.
local function workspace_name(dir)
	return (dir:match("([^/]+)/?$") or dir):gsub("[%. ]", "_")
end

local function shorten(dir)
	local home = wezterm.home_dir or ""
	if #home > 0 and dir:sub(1, #home) == home then
		return "~" .. dir:sub(#home + 1)
	end
	return dir
end

local open_project = wezterm.action_callback(function(window, pane, id)
	if not id then -- nil when cancelled
		return
	end
	local kind, value = id:match("^(%a+):(.*)$")
	if kind == "ws" then
		window:perform_action(act.SwitchToWorkspace({ name = value }), pane)
	elseif kind == "dir" then
		window:perform_action(act.SwitchToWorkspace({ name = workspace_name(value), spawn = { cwd = value } }), pane)
	end
end)

-- What each live workspace HOLDS, so a session line can say something useful
-- instead of just its name: tab count, and the directory the active tab sits in.
-- Walks the mux rather than shelling out, so it costs nothing.
local function workspace_summary()
	local info = {}
	local got, windows = pcall(wezterm.mux.all_windows)
	for _, w in ipairs(got and windows or {}) do
		local ok, ws = pcall(function()
			return w:get_workspace()
		end)
		if ok and ws then
			local entry = info[ws] or { tabs = 0, cwd = nil }
			local tabs = w:tabs()
			entry.tabs = entry.tabs + #tabs
			if not entry.cwd then
				local ok2, cwd = pcall(function()
					return w:active_pane():get_current_working_dir()
				end)
				-- Newer WezTerm hands back a Url object, older ones a plain string.
				if ok2 and cwd then
					entry.cwd = type(cwd) == "string" and cwd:gsub("^file://[^/]*", "") or cwd.file_path
				end
			end
			info[ws] = entry
		end
	end
	return info
end

-- Leader+f: the sessions you have, nothing else. Directories are a different
-- question and live behind ⌘P → "workspace: open project…" — mixing 500 folders
-- into this list buried the four things actually running.
local session_picker = wezterm.action_callback(function(window, pane)
	local t = active_theme
	local current = window:active_workspace()
	local summary = workspace_summary()
	local got, names = pcall(wezterm.mux.get_workspace_names)
	names = got and names or {}
	table.sort(names)

	local choices = {}
	for _, name in ipairs(names) do
		local s = summary[name] or { tabs = 0 }
		local here = name == current
		-- Formatted labels are explicitly supported: the docs note styling
		-- sequences are preserved during fuzzy matching without affecting the
		-- filter, so colour here costs nothing in searchability.
		table.insert(choices, {
			id = "ws:" .. name,
			label = wezterm.format({
				{ Foreground = { Color = here and t.accent or t.inactive_fg } },
				{ Text = (here and G.bolt or G.session) .. "  " },
				{ Attribute = { Intensity = here and "Bold" or "Normal" } },
				{ Foreground = { Color = t.active_fg } },
				{ Text = wezterm.pad_right(name, 24) },
				"ResetAttributes",
				{ Foreground = { Color = t.inactive_fg } },
				{ Text = string.format("%2d %s   %s", s.tabs, s.tabs == 1 and "tab " or "tabs", shorten(s.cwd or "")) },
			}),
		})
	end

	if #choices == 0 then
		window:toast_notification("wezterm", "No workspaces open", nil, 4000)
		return
	end
	window:perform_action(
		act.InputSelector({
			title = "sessions",
			fuzzy = true,
			fuzzy_description = "session: ",
			choices = choices,
			action = open_project,
		}),
		pane
	)
end)

-- The folder half, kept but moved off Leader+f (⌘P → "workspace: open project…").
local project_picker = wezterm.action_callback(function(window, pane)
	local t = active_theme
	local live = {}
	local got, names = pcall(wezterm.mux.get_workspace_names)
	for _, name in ipairs(got and names or {}) do
		live[name] = true
	end
	local choices = {}
	for _, dir in ipairs(project_dirs()) do
		local name = workspace_name(dir)
		table.insert(choices, {
			id = "dir:" .. dir,
			label = wezterm.format({
				{ Foreground = { Color = live[name] and t.accent or t.inactive_fg } },
				{ Text = (live[name] and G.bolt or G.files) .. "  " },
				{ Foreground = { Color = t.active_fg } },
				{ Text = wezterm.pad_right(name, 24) },
				"ResetAttributes",
				{ Foreground = { Color = t.inactive_fg } },
				{ Text = shorten(dir) },
			}),
		})
	end
	if #choices == 0 then
		window:toast_notification("wezterm", "No projects found under " .. PROJECTS, nil, 4000)
		return
	end
	window:perform_action(
		act.InputSelector({
			title = "projects",
			fuzzy = true,
			fuzzy_description = "open project: ",
			choices = choices,
			action = open_project,
		}),
		pane
	)
end)

-- ── URLs: open one without the mouse ─────────────────────────────────────────
-- The keyboard twin of the Cmd+click binding above. QuickSelect labels every
-- URL on screen, you type the label, the OS opens it — no copy mode, no
-- selection, no reaching for the trackpad. This is the good path; the copy-mode
-- binding below is only for when you are already in there.
--
-- skip_action_on_paste preserves QuickSelect's own case split: a lowercase label
-- runs the action (opens it), an uppercase label falls back to copying instead.
-- Patterns are Rust regex, like quick_select_patterns above — not Lua patterns.
-- \w+:// rather than https?:// so ssh://, git:// and file:// come along, and the
-- terminating class excludes the brackets and quotes that usually sit around a
-- URL in prose rather than inside it.
local open_url = act.QuickSelectArgs({
	label = "open url",
	patterns = { "\\b\\w+://[^\\s\"'<>()\\[\\]`]+" },
	skip_action_on_paste = true,
	action = wezterm.action_callback(function(window, pane)
		local url = window:get_selection_text_for_pane(pane)
		if url and #url > 0 then
			wezterm.open_with(url)
		end
	end),
})

-- Copy mode's version: open whatever is selected right now. Walking to a URL
-- with motions is strictly slower than open_url, so this exists for the case
-- where you are already in copy mode with a selection in hand.
local open_selection = wezterm.action_callback(function(window, pane)
	local sel = window:get_selection_text_for_pane(pane)
	if sel then
		sel = sel:gsub("^%s+", ""):gsub("%s+$", "")
		if #sel > 0 then
			wezterm.open_with(sel)
		end
	end
	window:perform_action(act.CopyMode("Close"), pane)
end)

config.keys = {
	-- Shift+Enter → CSI-u "Enter+Shift" (\x1b[13;2u) so apps (claude, nvim) insert a
	-- newline bare AND inside tmux: tmux forwards it through extended-keys (see
	-- tmux.conf). A bare "\n" works bare but doesn't survive tmux's key handling.
	{ key = "Enter", mods = "SHIFT", action = act.SendString("\x1b[13;2u") },

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

	-- Splits: cross nvim/tmux/WezTerm boundaries with one motion (see nav above)
	{ key = "h", mods = "CTRL", action = nav("h", "Left") },
	{ key = "j", mods = "CTRL", action = nav("j", "Down") },
	{ key = "k", mods = "CTRL", action = nav("k", "Up") },
	{ key = "l", mods = "CTRL", action = nav("l", "Right") },

	-- Splits: pane picker overlay
	{ key = "Space", mods = "LEADER", action = act.PaneSelect },

	-- Splits: zoom / swap / rotate / close. z, not f — tmux's zoom key, and f is
	-- the project picker in both layers now.
	{ key = "z", mods = "LEADER", action = act.TogglePaneZoomState },
	{ key = "=", mods = "LEADER", action = act.PaneSelect({ mode = "SwapWithActive" }) },
	{ key = "o", mods = "LEADER", action = act.RotatePanes("Clockwise") },
	-- confirm=true leans on skip_close_confirmation_for_processes_named, whose
	-- defaults already cover the shells and tmux: a prompt or a multiplexer closes
	-- instantly, an editor or an ssh asks first. confirm=false asked nothing, ever.
	{ key = "q", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },

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
	{ key = "<", mods = "LEADER|SHIFT", action = act.MoveTabRelative(-1) }, -- tmux's prefix+< (swap-window)
	{ key = ">", mods = "LEADER|SHIFT", action = act.MoveTabRelative(1) },

	-- Windows
	{ key = "c", mods = "LEADER|SHIFT", action = act.SpawnWindow },

	-- Scrolling
	{ key = "u", mods = "LEADER", action = act.ScrollByPage(-1) },
	{ key = "d", mods = "LEADER", action = act.ScrollByPage(1) },
	{ key = "g", mods = "LEADER", action = act.ScrollToTop },
	{ key = "g", mods = "LEADER|SHIFT", action = act.ScrollToBottom },
	-- Jump by prompt rather than by page — needs the OSC 133 marks the shell
	-- integration emits (config/shell/inits.zsh), and is inert without them.
	{ key = "UpArrow", mods = "CMD|SHIFT", action = act.ScrollToPrompt(-1) },
	{ key = "DownArrow", mods = "CMD|SHIFT", action = act.ScrollToPrompt(1) },

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
	-- Label every URL on screen and open the one you name (see open_url).
	{ key = "o", mods = "LEADER|SHIFT", action = open_url },

	-- Copy / paste
	{ key = "y", mods = "LEADER", action = act.CopyTo("ClipboardAndPrimarySelection") },
	{ key = "v", mods = "LEADER", action = act.PasteFrom("Clipboard") },

	-- Font size: use built-in Cmd+= / Cmd+- / Cmd+0 (no leader needed)

	-- Launcher menu (btop, yazi, lazygit, etc.)
	{ key = "m", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "FUZZY|LAUNCH_MENU_ITEMS" }) },

	-- Workspaces. w = the ones already open (tmux's prefix+s), f = pick a project
	-- and open one (tmux's prefix+f).
	{ key = "w", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
	{ key = "f", mods = "LEADER", action = session_picker },
	{ key = "}", mods = "LEADER", action = act.SwitchWorkspaceRelative(1) },
	{ key = "{", mods = "LEADER", action = act.SwitchWorkspaceRelative(-1) },

	-- Detach this tab's domain — only the persistent one supports it, and its
	-- panes keep running (reattach from the ⌘P palette). A no-op on local panes.
	{ key = "d", mods = "LEADER|SHIFT", action = act.DetachDomain("CurrentPaneDomain") },
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

-- Copy mode: EXTEND the built-ins, never assign the table outright. key_tables is
-- replace-by-name, not merge — config.rs does `tables.by_name.insert(name, table)`
-- for each entry, so `config.key_tables.copy_mode = {…}` would silently drop all
-- 62 default vi bindings and leave copy mode with only whatever is listed here.
-- default_key_tables() hands back those defaults to append to. (Defining `resize`
-- above is safe for exactly the same reason: it only replaces `resize`.)
--
-- wezterm.gui is nil in the mux server, same as in appearance() at the top — so
-- this is skipped there, which is harmless because key tables are a GUI concern.
local gui = wezterm.gui
if gui and gui.default_key_tables then
	local copy_mode = gui.default_key_tables().copy_mode
	if copy_mode then
		for _, k in ipairs({
			-- '/' is genuinely absent from the defaults, so a search could only be
			-- started from normal mode (Leader+/). tmux has it inside copy mode, and
			-- n/N to walk the matches; this restores both.
			{ key = "/", mods = "NONE", action = act.CopyMode("EditPattern") },
			{ key = "n", mods = "NONE", action = act.CopyMode("NextMatch") },
			{ key = "N", mods = "SHIFT", action = act.CopyMode("PriorMatch") },
			-- Open the current selection. Ctrl+o because plain o and O are both
			-- taken by the defaults (MoveToSelectionOtherEnd / …Horiz).
			{ key = "o", mods = "CTRL", action = open_selection },
		}) do
			table.insert(copy_mode, k)
		end
		config.key_tables.copy_mode = copy_mode
	end
end

-- ── Status bar ───────────────────────────────────────────────────────────────
-- Left: the workspace as a pill, in the shape and accent tmux gives the session
-- on the row directly below — the two bars read as one stack, outer session over
-- inner. Right: [KEY TABLE] · battery.
--
-- Holding the leader FILLS the pill and swaps its glyph for a bolt, which is
-- exactly what tmux's status-left does when the prefix is held
-- (`#{?client_prefix,#[reverse],}` + the same two glyphs, restated here). Each
-- bar lights its own pill for its own prefix, so there is no separate LEADER
-- badge: the indicator is the thing it applies to. Both states are one cell wide
-- for the same reason tmux's are — a width change would shove the tabs sideways
-- on every press.
config.status_update_interval = 1000

local function render(segments)
	local elements = {}
	for _, seg in ipairs(segments) do
		table.insert(elements, { Background = { Color = seg.bg } })
		table.insert(elements, { Foreground = { Color = seg.fg } })
		table.insert(elements, { Attribute = { Intensity = "Bold" } })
		table.insert(elements, { Text = seg.text })
	end
	table.insert(elements, "ResetAttributes")
	return wezterm.format(elements)
end

-- Battery is native, so it costs no subprocess and can be read every tick.
local function battery()
	local ok, info = pcall(wezterm.battery_info)
	if not ok or not info or #info == 0 then
		return nil
	end
	local b = info[1]
	local pct = math.floor((b.state_of_charge or 0) * 100 + 0.5)
	-- 0-100 onto the five empty→full glyphs; +1 because Lua indexes from one.
	local glyph = G.battery[math.min(5, math.floor(pct / 20) + 1)]
	if b.state == "Charging" then
		glyph = G.bolt -- charging says more than the level does
	end
	return glyph, pct .. "%", pct <= 20 and b.state == "Discharging"
end

-- CPU / RAM / disk in ONE shell round trip, on a timer rather than per redraw:
-- update-status fires every second and none of these move that fast. Measured
-- ~20ms for the batch (iostat was rejected — its two-sample form blocks a full
-- second), against a 5s refresh, which is also tmux's status-interval.
--
-- The arithmetic deliberately matches what tmux's bar shows so the two rows can
-- never disagree: CPU is summed ps %cpu over core count, RAM is vm_stat's
-- active+wired+compressed, disk is df on /.
local METRICS_SH = [[
ncpu=$(sysctl -n hw.ncpu)
cpu=$(ps -A -o %cpu= | awk -v n="$ncpu" '{s+=$1} END {printf "%.0f", (s/n > 100 ? 100 : s/n)}')
ram=$(vm_stat | awk -v total="$(sysctl -n hw.memsize)" '
  /page size of/{p=$8} /Pages active/{a=$3} /Pages wired/{w=$4} /Pages occupied by compressor/{c=$5}
  END{gsub(/\./,"",a);gsub(/\./,"",w);gsub(/\./,"",c);printf "%.0f",(a+w+c)*p/total*100}')
ssd=$(df -h / | awk 'NR==2{gsub(/%/,"",$5);print $5}')
printf '%s\t%s\t%s' "$cpu" "$ram" "$ssd"
]]

local metrics = { at = 0 }
local METRICS_EVERY = 5

local function refresh_metrics()
	local now = os.time()
	if now - metrics.at < METRICS_EVERY then
		return
	end
	metrics.at = now
	-- capture() pcalls: run_child_process raises rather than returning false when
	-- it can't spawn, and a status bar must never be able to take the GUI down.
	local out = capture({ "/bin/sh", "-c", METRICS_SH })
	if out then
		local cpu, ram, ssd = out:match("^(%S*)\t(%S*)\t(%S*)")
		if cpu then
			metrics.cpu, metrics.ram, metrics.ssd = cpu, ram, ssd
		end
	end
end

wezterm.on("update-status", function(window, _pane)
	local t = theme_for_appearance(window:get_appearance())

	-- Refresh the process cache the tab bar reads (see pane_prog). Walks every mux
	-- window rather than just the one that ticked: the table is rebuilt from
	-- scratch, so scoping it to this window would blank every other window's tabs
	-- once a second. all_windows can raise ("cannot get Mux!?"), and a status bar
	-- must never be able to take the GUI down, so it is pcall'd like the rest.
	local got, mux_windows = pcall(wezterm.mux.all_windows)
	if got then
		local fresh = {}
		for _, w in ipairs(mux_windows) do
			for _, mux_tab in ipairs(w:tabs()) do
				for _, p in ipairs(mux_tab:panes()) do
					local proc = p:get_foreground_process_name()
					if proc then
						fresh[p:pane_id()] = proc:match("[^/]+$")
					end
				end
			end
		end
		pane_prog = fresh
	end

	local armed = window:leader_is_active()
	window:set_left_status(render({
		{
			bg = armed and t.accent or t.frame_bg,
			fg = armed and t.frame_bg or t.accent,
			text = " " .. (armed and G.bolt or G.session) .. "  " .. window:active_workspace() .. " ",
		},
		{ bg = t.frame_bg, fg = t.frame_bg, text = " " },
	}))

	local segments = {}

	-- Active key table (Catppuccin yellow on base)
	local kt = window:active_key_table()
	if kt then
		table.insert(segments, { bg = t.ktable_bg, fg = t.ktable_fg, text = " " .. kt:upper() .. " " })
	end

	-- The metric row. Each glyph carries the accent and its value reads plain, so
	-- the row scans as icon/number pairs rather than one wall of text.
	refresh_metrics()
	local cells = {}
	local function cell(glyph, value, warn)
		if value then
			table.insert(cells, { glyph = glyph, value = value, warn = warn })
		end
	end
	cell(G.cpu, metrics.cpu and metrics.cpu .. "%", tonumber(metrics.cpu or 0) >= 90)
	cell(G.ram, metrics.ram and metrics.ram .. "%", tonumber(metrics.ram or 0) >= 90)
	cell(G.disk, metrics.ssd and metrics.ssd .. "%", tonumber(metrics.ssd or 0) >= 90)
	local bat_glyph, bat_pct, bat_low = battery()
	cell(bat_glyph, bat_pct, bat_low)
	cell(G.clock, wezterm.strftime("%H:%M"))
	cell(G.calendar, wezterm.strftime("%a %d %b"))

	for _, c in ipairs(cells) do
		table.insert(segments, { bg = t.frame_bg, fg = c.warn and t.leader_bg or t.accent, text = " " .. c.glyph })
		if #c.value > 0 then
			table.insert(segments, { bg = t.frame_bg, fg = t.frame_fg, text = " " .. c.value })
		end
	end
	table.insert(segments, { bg = t.frame_bg, fg = t.frame_bg, text = "  " })

	window:set_right_status(render(segments))
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
local tmux_bin = find_bin("tmux")

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
			brief = "workspace: open project…",
			icon = "md_folder_open",
			action = project_picker,
		},
		-- Persistence, opted into one tab at a time — see the unix_domains block.
		{
			brief = "domain: attach persistent (panes survive a restart)",
			icon = "md_pin",
			action = act.AttachDomain("persist"),
		},
		{
			brief = "domain: detach (leave the panes running)",
			icon = "md_pin_off",
			action = act.DetachDomain("CurrentPaneDomain"),
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
