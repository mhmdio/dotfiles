-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- True color: set explicitly (LazyVim enables it by default — don't rely on that).
vim.opt.termguicolors = true

-- LazyVim ships pumblend=10; blended popups read muddy against a translucent
-- terminal. Solid menus, same reasoning as transparent_background=false.
vim.opt.pumblend = 0
