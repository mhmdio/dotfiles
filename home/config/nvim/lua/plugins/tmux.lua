-- Seamless C-h/j/k/l navigation between nvim splits and tmux panes (the tmux
-- side is vim-tmux-navigator too, wired in home/tmux.nix). vim-obsession writes
-- a Session.vim so tmux-resurrect can bring the editor back (@resurrect-strategy-nvim).
return {
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
    },
    keys = {
      { "<c-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Go to left pane" },
      { "<c-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Go to lower pane" },
      { "<c-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Go to upper pane" },
      { "<c-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Go to right pane" },
    },
  },
  { "tpope/vim-obsession", cmd = "Obsession" },
}
