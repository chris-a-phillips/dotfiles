return {
	-- 1️⃣ Load LazyVim Core Plugins First
	{ import = "lazyvim.plugins" },

	-- 2️⃣ Load LazyVim Extras Next
	{ import = "lazyvim.plugins.extras.ui.mini-starter" },
	{ import = "lazyvim.plugins.extras.lang.json" },
	{ import = "lazyvim.plugins.extras.lang.typescript" },

	-- 3️⃣ Now Load Your Custom Plugins

	-- Add colorschemes
	{ "folke/tokyonight.nvim" },

	-- Configure LazyVim to use tokyonight theme
	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "tokyonight",
		},
	},

	-- Change Trouble config
	{
		"folke/trouble.nvim",
		opts = { use_diagnostic_signs = true },
	},

	-- Disable Trouble
	-- { "folke/trouble.nvim", enabled = false },

	-- Override nvim-cmp and add cmp-emoji
	{
		"hrsh7th/nvim-cmp",
		dependencies = { "hrsh7th/cmp-emoji" },
		opts = function(_, opts)
			table.insert(opts.sources, { name = "emoji" })
		end,
	},

	-- Change some Telescope options and add a keymap
	{
		"nvim-telescope/telescope.nvim",
		keys = {
			{
				"<leader>fp",
				function()
					require("telescope.builtin").find_files({ cwd = require("lazy.core.config").options.root })
				end,
				desc = "Find Plugin File",
			},
		},
		opts = {
			defaults = {
				layout_strategy = "horizontal",
				layout_config = { prompt_position = "top" },
				sorting_strategy = "ascending",
				winblend = 0,
			},
		},
	},

	-- Add pyright to LSP
	{
		"neovim/nvim-lspconfig",
		opts = {
			servers = {
				pyright = {},
				black = {},
				eslint = {},
				emmet_language_server = {},
				emmet_ls = {},
				gopls = {},
				sqlls = {},
				markdown_oxide = {},
				lua_ls = {},
				rust_analyzer = {},
				phpactor = {},
			},
		},
	},

	-- Add tsserver and configure with typescript.nvim
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"jose-elias-alvarez/typescript.nvim",
			init = function()
				require("lazyvim.util").lsp.on_attach(function(_, buffer)
					vim.keymap.set(
						"n",
						"<leader>co",
						"TypescriptOrganizeImports",
						{ buffer = buffer, desc = "Organize Imports" }
					)
					vim.keymap.set("n", "<leader>cR", "TypescriptRenameFile", { desc = "Rename File", buffer = buffer })
				end)
			end,
		},
		opts = {
			servers = {
				tsserver = {},
			},
			setup = {
				tsserver = function(_, opts)
					require("typescript").setup({ server = opts })
					return true
				end,
			},
		},
	},

	-- Add more Treesitter parsers
	{
		"nvim-treesitter/nvim-treesitter",
		opts = {
			ensure_installed = {
				"bash",
				"html",
				"javascript",
				"json",
				"lua",
				"markdown",
				"markdown_inline",
				"python",
				"query",
				"regex",
				"tsx",
				"typescript",
				"vim",
				"yaml",
			},
		},
	},

	-- Extend Treesitter parsers
	{
		"nvim-treesitter/nvim-treesitter",
		opts = function(_, opts)
			vim.list_extend(opts.ensure_installed, { "tsx", "typescript" })
		end,
	},

	-- Customize Lualine
	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		opts = function(_, opts)
			table.insert(opts.sections.lualine_x, {
				function()
					return "😄"
				end,
			})
		end,
	},

	-- Override Lualine defaults
	{
		"nvim-lualine/lualine.nvim",
		event = "VeryLazy",
		opts = function()
			return {
				--[[ Custom Lualine Config ]]
			}
		end,
	},

	-- Add Mason tools
	{
		"williamboman/mason.nvim",
		opts = {
			ensure_installed = {
				"stylua",
				"shellcheck",
				"shfmt",
				"flake8",
			},
		},
	},

	-- EXTRA PLUGINS

	-- Arrow.nvim
	{
		"otavioschwanck/arrow.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {
			show_icons = true,
			leader_key = ";",
			buffer_leader_key = "'",
			mappings = {
				edit = "e",
				delete_mode = "d",
				clear_all_items = "C",
				toggle = "s",
				open_vertical = "|",
				open_horizontal = "-",
				quit = "q",
				remove = "x",
				next_item = "]",
				prev_item = "[",
			},
		},
	},

	-- Auto-activate Python virtual environments
	{ "sansyrox/vim-python-virtualenv" },

	-- Screenkey
	{
		"NStefan002/screenkey.nvim",
		lazy = false,
		version = "*",
	},

	-- Undotree
	{
		"jiaoshijie/undotree",
		dependencies = "nvim-lua/plenary.nvim",
		config = true,
		keys = {
			{ "<leader>u", "<cmd>lua require('undotree').toggle()<cr>" },
		},
	},

	-- Multiple cursors
	{ "mg979/vim-visual-multi" },

	-- Tmux navigation
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
			{ "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
			{ "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
			{ "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
			{ "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
			{ "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
		},
	},
}
