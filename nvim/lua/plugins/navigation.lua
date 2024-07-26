return {
	-- For navigating my project structure in the way that I"m used to with IDEs
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			"MunifTanjim/nui.nvim",
		},
		config = function()
			require("neo-tree").setup {
				filesystem = {
					hijack_netrw_behavior = "open_current"
				}
			}
		end
	},

	-- For finding files quickly
	{
		"nvim-telescope/telescope.nvim", 
		branch = "0.1.x",
		dependencies = { 
			-- Helper lib for telescope
			{ "nvim-lua/plenary.nvim" },
			-- Faster sorting
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
			-- Ability to pass ripgrep arguments to the live_grep picker
			{ "nvim-telescope/telescope-live-grep-args.nvim" , version = "^1.0.0" },
		},
		config = function()
			local telescope = require("telescope")
			telescope.load_extension("fzf")
			telescope.load_extension("live_grep_args")
			local builtin = require("telescope.builtin")

			vim.keymap.set("n", "<leader>ff", builtin.find_files, {})
			vim.keymap.set("n", "<leader>fh", builtin.help_tags, {})
			vim.keymap.set("n", "<leader>fg", builtin.live_grep, {})
		end
	}
}
