-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
-- syntax -> vim.keymap.set("mode", "key combination", "action", { desc = "description" })

vim.keymap.set("n", "<leader>cn", function()
	require("lazyvim.util").terminal({ "navi" }, { cwd = vim.loop.cwd() })
end, { desc = "Open Navi in Floating Terminal" })

-- Remove things from ui so its not so cluttered
vim.keymap.del("n", "<leader>E") -- Remove Snacks (cwd) (duplicate)
vim.keymap.del("n", "<leader>L") -- Remove LazyVim changelog (not useful)
vim.keymap.del("n", "<leader>S") -- Remove Select Scratch Buffer (not useful)
vim.keymap.del("n", "<leader>`") -- Remove Switch to Other Buffer (not useful)
vim.keymap.del("n", "<leader>fT") -- Remove Terminal (cwd) (duplicate)

-- CUSTOM KEYMAPS
-- easy buffer resize
vim.keymap.set("n", "<S-Right>", ":vertical resize -5<CR>", { desc = "Decrease window width" })
vim.keymap.set("n", "<S-Left>", ":vertical resize +5<CR>", { desc = "Increase window width" })
vim.keymap.set("n", "<S-Up>", ":resize +5<CR>", { desc = "Increase window height" })
vim.keymap.set("n", "<S-Down>", ":resize -5<CR>", { desc = "Decrease window height" })

-- go to definition in normal mode
vim.keymap.set("n", "gp", "<cmd>lua require('goto-preview').goto_preview_definition()<CR>", { noremap = true })

-- move entire lines
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move line(s) up" })
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move line(s) down" })

-- paste and ignore new register
vim.keymap.set("x", "<leader>p", '"_dP', { desc = "Paste without overwriting register" })
vim.keymap.set("n", "<leader>p", '"_dP', { desc = "Paste without overwriting register" })
vim.keymap.set("v", "<leader>p", '"_dP', { desc = "Paste without overwriting register" })

-- search and replace
vim.keymap.set(
	"n",
	"<leader>r",
	[[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
	{ desc = "Global search and replace" }
)
