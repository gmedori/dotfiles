-- gitsigns provides a git gutter showing which lines have a git status associated with them
return {
	'lewis6991/gitsigns.nvim',
	opts = {
		on_attach = function(bufnr)
			local gs = require('gitsigns')
			vim.keymap.set('n', 'gn', function() gs.nav_hunk('next') end, { buffer = bufnr, desc = 'Go to next git hunk' })
			vim.keymap.set('n', 'gp', function() gs.nav_hunk('prev') end, { buffer = bufnr, desc = 'Go to prev git hunk' })
		end,
	},
}
