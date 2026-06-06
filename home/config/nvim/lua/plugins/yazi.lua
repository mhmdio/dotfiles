-- yazi.nvim — same file manager inside nvim as in the terminal.
-- <leader>- opens yazi at the current file; replaces netrw for directories.
return {
  "mikavilpas/yazi.nvim",
  version = "*",
  event = "VeryLazy",
  dependencies = { { "nvim-lua/plenary.nvim", lazy = true } },
  keys = {
    { "<leader>-", mode = { "n", "v" }, "<cmd>Yazi<cr>", desc = "Yazi at current file" },
    { "<leader>cw", "<cmd>Yazi cwd<cr>", desc = "Yazi in working dir" },
    { "<c-up>", "<cmd>Yazi toggle<cr>", desc = "Resume last yazi" },
  },
  opts = {
    open_for_directories = true,
    keymaps = { show_help = "<f1>" },
  },
  init = function()
    vim.g.loaded_netrwPlugin = 1
  end,
}
