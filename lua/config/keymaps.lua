-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

vim.keymap.set("n", "<leader>ch", function()
  require("lazyvim.util").terminal({ "navi" }, { cwd = vim.loop.cwd() })
end, { desc = "Open Navi in Floating Terminal" })

-- Remove things from ui so its not so cluttered
vim.keymap.del("n", "<leader>E") -- Remove Snacks (cwd) (duplicate)
vim.keymap.del("n", "<leader>L") -- Remove LazyVim changelog (not useful)
vim.keymap.del("n", "<leader>S") -- Remove Select Scratch Buffer (not useful)
vim.keymap.del("n", "<leader>`") -- Remove Switch to Other Buffer (not useful)
vim.keymap.del("n", "<leader>fT") -- Remove Terminal (cwd) (duplicate)

vim.keymap.set("n", "<S-Right>", ":vertical resize -5<CR>", { desc = "Decrease window width" })
vim.keymap.set("n", "<S-Left>", ":vertical resize +5<CR>", { desc = "Increase window width" })
vim.keymap.set("n", "<S-Up>", ":resize +5<CR>", { desc = "Increase window height" })
vim.keymap.set("n", "<S-Down>", ":resize -5<CR>", { desc = "Decrease window height" })
