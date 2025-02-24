-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Sync clipboard between OS and Neovim.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.opt.clipboard = "unnamedplus"

-- Configure how new splits should be opened
vim.opt.splitright = true

-- Minimal number of screen lines to keep cursor centered
vim.opt.scrolloff = 999

-- Searches ignore case unless using uppercase letters
vim.opt.ignorecase = true
vim.opt.smartcase = true

--Helps see spaces, tabs, and line endings
vim.opt.list = true
vim.opt.listchars = {
	tab = "→ ", -- tab
	-- space = "·", -- space
	-- eol = "↲", -- end of line
	trail = "␣", -- trailing whitespace
	extends = "»", -- if line extends beyond screen width
	precedes = "«", -- if line has hidden text before screen starts
	-- nbsp = "␣", -- non-breaking spaces (\xa0)
	lead = "·", -- leading spaces
	multispace = "·", -- multiple spaces
}

-- Faster key mappings & which-key.nvim responsiveness
vim.opt.timeoutlen = 300 -- Default is 1000ms (1s)
-- Faster LSP, GitGutter, diagnostics updates
vim.opt.updatetime = 200 -- Default is 4000ms (4s)
