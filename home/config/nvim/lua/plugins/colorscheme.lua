-- nvim detects the terminal background; catppuccin flavour="auto" maps it to
-- Mocha (dark) / Latte (light). No OS queries, no custom switching.
return {
  { "LazyVim/LazyVim", opts = { colorscheme = "catppuccin" } },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    opts = {
      flavour = "auto",
      background = { light = "latte", dark = "mocha" },
      transparent_background = true,
    },
  },
}
