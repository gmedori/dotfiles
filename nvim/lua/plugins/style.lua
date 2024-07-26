return {
	-- Testing this color scheme out
	{ "catppuccin/nvim", name = "catppuccin", priority = 1000, lazy = false },

	-- My primary colorscheme. Has been for a long time.
	{ 
		"gposcidonio/badwolf",
		lazy = false ,
		config = function()
			vim.cmd("colorscheme badwolf")
		end
	},

	-- For a nice status line
	{ 
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons", opt = true },
		config = function()
			require("lualine").setup()
		end,
	},

	-- For git symbols/colors in the gutter
	{
		"lewis6991/gitsigns.nvim",
		config = function()
			require("gitsigns").setup()
		end
	}
}
