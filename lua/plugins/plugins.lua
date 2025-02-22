if true then
  return {
    -- Colorscheme
    {
      "folke/tokyonight.nvim",
      opts = {
        transparent = true, -- This enables transparency
        style = "storm", -- You can change this to 'night', 'moon', or 'day'
        terminal_colors = true,
        styles = {
          sidebars = "transparent", -- Sidebar transparency
          floats = "transparent", -- Floating window transparency
        },
      },
      config = function(_, opts)
        require("tokyonight").setup(opts)
        vim.cmd([[colorscheme tokyonight]])
      end,
    },
    -- Trouble
    {
      "folke/trouble.nvim",
      -- opts will be merged with the parent spec
      opts = { use_diagnostic_signs = true },
    },
    -- Snacks explorer options
    {
      {
        "folke/snacks.nvim",
        opts = {
          picker = {
            hidden = true, -- for hidden files
            ignored = true, -- for .gitignore files
          },
        },
      },
    },
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
    -- Undotree
    {
      "jiaoshijie/undotree",
      dependencies = "nvim-lua/plenary.nvim",
      config = true,
      keys = {
        { "<leader>u", "<cmd>lua require('undotree').toggle()<cr>" },
      },
    },
    -- Auto-activate Python virtual environments
    { "sansyrox/vim-python-virtualenv" },
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
    -- Screenkey
    {
      "NStefan002/screenkey.nvim",
      lazy = false,
      version = "*",
    },
    -- Supermaven
    {
      "supermaven-inc/supermaven-nvim",
      version = "*", -- or specify a version string, e.g., "1.0.0"
      lazy = false, -- Set to true if you want to load the plugin lazily
      config = function()
        require("supermaven-nvim").setup({})
      end,
    },
    -- Multiple cursors
    {
      "mg979/vim-visual-multi",
      branch = "master",
      config = function()
        -- Any specific configuration for vim-visual-multi can go here
      end,
    },
    -- Go to preview
    {
      "rmagatti/goto-preview",
      event = "BufEnter",
      config = true, -- necessary as per https://github.com/rmagatti/goto-preview/issues/88
    },
    -- Vim motions practice
    { "ThePrimeagen/vim-be-good" }, -- start with practice :VimBeGood
    -- View CSV files
    {
      "cameron-wags/rainbow_csv.nvim",
      config = true,
      ft = {
        "csv",
        "tsv",
        "csv_semicolon",
        "csv_whitespace",
        "csv_pipe",
        "rfc_csv",
        "rfc_semicolon",
      },
      cmd = {
        "RainbowDelim",
        "RainbowDelimSimple",
        "RainbowDelimQuoted",
        "RainbowMultiDelim",
      },
    },
  }
end
