-- nvim detects the terminal background; catppuccin flavour="auto" maps it to
-- Mocha (dark) / Latte (light). No OS queries, no custom switching.
--
-- The scheme is "catppuccin-nvim", NOT "catppuccin": Neovim 0.12 bundles its own
-- $VIMRUNTIME/colors/catppuccin.vim, which wins that name and means the plugin's
-- load() never runs. Colours still looked Latte (the bundled port is Catppuccin
-- too), but the plugin's flavour stayed nil, so anything asking it for a palette
-- got its "mocha" default — bufferline drew a dark strip over a light buffer —
-- and lualine, finding no themes/catppuccin.lua, fell back to grey. The plugin's
-- own entry point is colors/catppuccin-nvim.vim; it sets colors_name to
-- catppuccin-<flavour>, which both of those then resolve correctly.
--
-- transparent_background stays OFF, and there's nothing left for it to fix:
-- WezTerm is opaque now (wezterm.lua). Turning it ON was the other way to close
-- the seam between an opaque editor and a translucent window, but it costs the
-- editor its own background — every cell falls back to the default one, so
-- CursorLine, Pmenu and floats composite against the desktop instead of layering.
return {
  { "LazyVim/LazyVim", opts = { colorscheme = "catppuccin-nvim" } },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    opts = {
      flavour = "auto",
      background = { light = "latte", dark = "mocha" },
      transparent_background = false,
    },
  },
}
