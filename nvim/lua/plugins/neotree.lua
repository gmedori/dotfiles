return {
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			"nvim-tree/nvim-web-devicons", -- optional, but recommended
		},
		lazy = false, -- neo-tree will lazily load itself
		config = function() 
			vim.keymap.set('n', '<leader><tab>', ':Neotree toggle position=left<CR>', { noremap = true, silent = true })
			vim.keymap.set('n', '<C-S-j>', ':Neotree reveal<CR>', { noremap = true })
		end
	}
}
