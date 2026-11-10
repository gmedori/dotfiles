local selected = "badwolf"

return {
	{
		"neanias/everforest-nvim",
		version = false,
		lazy = selected ~= "everforest",
		priority = 1000, -- make sure to load this before all the other start plugins
		-- Optional; default configuration will be used if setup isn't called.
		config = function()
			if selected == "everforest" then
				require("everforest").load() -- Enable the colorscheme
			end
		end,
	},
	{
		"sjl/badwolf",
		lazy = selected ~= "badwolf",
		priority = 1000,
		config = function()
			if selected == "badwolf" then
				vim.cmd.colorscheme("badwolf")
			end
		end,
	},
}
