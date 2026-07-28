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
-- transparent_background stays OFF on purpose. WezTerm's text_background_opacity
-- is 1.0, and it applies to "cells other than the default background color" — so
-- a colorscheme that paints Normal gets drawn fully opaque even though the window
-- is translucent. Transparent nvim means every cell falls back to the default bg,
-- i.e. the editor is composited against the blurred desktop: washed-out colour,
-- and CursorLine/Pmenu/floats lose the layering they rely on. This way the shell
-- stays glassy and the editor is crisp. One line to flip back if you miss it.
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
