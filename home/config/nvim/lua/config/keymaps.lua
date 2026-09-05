-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- ── superfile (spf) as a file picker ────────────────────────────────────────
-- <leader>_ opens superfile as a file picker: "go find a file, open it here".
--
-- No plugin needed — superfile ships `--chooser-file` for exactly this case
-- (src/cmd/main.go: "On trying to open any file, superfile will write its path
-- to this file, and exit"). The two superfile plugins on GitHub are 1- and
-- 12-star wrappers around the same flag, so this skips the dependency.
--
-- The other direction is superfile's own config: editor = $EDITOR and
-- dir_editor = nvim (home/config/superfile/config.toml), so opening anything
-- from inside spf comes back to nvim.
local function superfile_pick()
  -- Read this BEFORE opening the float: nvim_open_win enters the new scratch
  -- buffer, after which `%` is that buffer and this always fell back to cwd.
  local start = vim.fn.expand("%:p:h")
  if start == "" then
    start = vim.fn.getcwd()
  end

  local chooser = vim.fn.tempname()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"

  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.9)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
  })

  local on_exit = function()
    -- Scheduled: on_exit can fire in a context where window/buffer calls aren't
    -- allowed yet.
    vim.schedule(function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
      local ok, lines = pcall(vim.fn.readfile, chooser)
      vim.fn.delete(chooser)
      -- Quitting spf without opening anything leaves the file empty: do nothing.
      if not ok or vim.tbl_isempty(lines or {}) or lines[1] == "" then
        return
      end
      vim.cmd.edit(vim.fn.fnameescape(lines[1]))
    end)
  end

  -- jobstart{term=true}, not termopen() — the latter is deprecated since 0.11.
  vim.fn.jobstart({ "spf", "--chooser-file", chooser, start }, { term = true, on_exit = on_exit })
  vim.cmd.startinsert()
end

-- lua/ ships to every profile (home/dotfiles/core.nix), but superfile is a
-- macOS Homebrew formula — nixpkgs is on 1.3.3 and no Linux profile installs
-- it. Map only where the binary exists, rather than hand Linux a key that
-- fails with "spf: command not found".
if vim.fn.executable("spf") == 1 then
  vim.keymap.set("n", "<leader>_", superfile_pick, { desc = "superfile (pick a file)" })
end
