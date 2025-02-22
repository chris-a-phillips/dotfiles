-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("n", "<leader>ch", function()
  require("lazyvim.util").terminal({ "navi" }, { cwd = vim.loop.cwd() })
end, { desc = "Open Navi in Floating Terminal" })

vim.keymap.del("n", "<leader>E") -- Remove Snacks (cwd)
vim.keymap.del("n", "<leader>L") -- Remove LazyVim changelog (not useful)
