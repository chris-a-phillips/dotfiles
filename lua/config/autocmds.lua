-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
--

-- Automatically start screenkey
local screenkey = require("screenkey")

-- Ensure screenkey is initialized before using it
screenkey.setup({})

-- Auto-start screenkey when Neovim enters the UI
vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    screenkey.toggle() -- Automatically turns it on
  end,
})

-- Enable numbers and relative numbers in snacks explorer
vim.defer_fn(function()
  vim.cmd("set number")
  vim.cmd("set relativenumber")
end, 100) -- Small delay to ensure LazyVim finishes loading

vim.cmd([[
  autocmd BufNewFile,BufRead *.csv   set filetype=csv
]])
