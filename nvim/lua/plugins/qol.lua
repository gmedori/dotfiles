return {
	-- For a fancy start screen
	{  
		"mhinz/vim-startify", 
		lazy = false 
	},

	-- For no more accidental empty files
	{
		"EinfachToll/DidYouMean",
		lazy = true
	},

	-- What key does that thing again?
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts = {
			-- TODO
		},
		keys = {
			{
				"<leader>?",
				function()
					require("which-key").show({ global = false })
				end,
				desc = "Buffer Local Keymaps (which-key)",
			},
		},
	}
}
