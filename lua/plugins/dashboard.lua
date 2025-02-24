return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	opts = {
		bigfile = { enabled = true },
		dashboard = {
			preset = {
				header = table.concat({
					[[   █  █   ]],
					[[   █ ██   ]],
					[[   ████   ]],
					[[   ██ ███   ]],
					[[   █  █   ]],
					[[             ]],
					[[ n e o v i m ]],
				}, "\n"),
			},
			enable = true,
			formats = {
				key = function(item)
					return { { "[", hl = "special" }, { item.key, hl = "key" }, { "]", hl = "special" } }
				end,
			},
			sections = {
				{ section = "header", indent = 60 },
				{
					{ section = "keys", gap = 1, padding = 1 },
					{ section = "startup", indent = 60, padding = 5 },
				},
				{
					pane = 2,
					section = "terminal",
					cmd = "",
					height = 5,
					padding = 6,
					indent = 10,
				},
				{
					pane = 2,
					{
						icon = " ",
						title = "Recent Files",
						padding = 1,
					},
					{
						section = "recent_files",
						opts = { limit = 3 },
						indent = 2,
						padding = 1,
					},
					{
						icon = " ",
						title = "Projects",
						padding = 1,
					},
					{
						section = "projects",
						opts = { limit = 3 },
						indent = 2,
						padding = 1,
					},
				},
			},
		},
		indent = { enabled = true },
		input = { enabled = true },
		rename = { enabled = true },
		notifier = {
			enabled = true,
			style = "fancy",
		},
		notify = { enabled = true },
		dim = { enabled = true },
		quickfile = { enabled = true },
		scroll = { enabled = true },
		statuscolumn = { enabled = true },
		words = { enabled = true },
	},

	keys = {
		{
			"<leader>nn",
			function()
				Snacks.notifier.show_history()
			end,
			desc = "Notification History",
		},
		{
			"<leader>gB",
			function()
				Snacks.gitbrowse()
			end,
			desc = "Git Browse",
			mode = { "n", "v" },
		},
		{
			"<leader>gb",
			function()
				Snacks.git.blame_line()
			end,
			desc = "Git Blame Line",
		},
		{
			"<leader>gf",
			function()
				Snacks.lazygit.log_file()
			end,
			desc = "Lazygit Current File History",
		},
		{
			"<leader>gg",
			function()
				Snacks.lazygit()
			end,
			desc = "Lazygit",
		},
		{
			"<leader>gl",
			function()
				Snacks.lazygit.log()
			end,
			desc = "Lazygit Log (cwd)",
		},
		{
			"<leader>rf",
			function()
				Snacks.rename.rename_file()
			end,
			desc = "Rename File",
		},
	},
}
