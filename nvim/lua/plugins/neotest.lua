return {
	'nvim-neotest/neotest',
	dependencies = {
		'nvim-neotest/nvim-nio',
		'nvim-lua/plenary.nvim',
		'nvim-treesitter/nvim-treesitter',
		{
			'fredrikaverpil/neotest-golang',
			version = '*',
		},
	},
	config = function()
		local neotest = require 'neotest'

		local function open_summary()
			for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
				local buf = vim.api.nvim_win_get_buf(win)
				if vim.bo[buf].filetype == 'neo-tree' then
					vim.api.nvim_set_current_win(win)
					vim.cmd 'belowright 15split'
					return vim.api.nvim_get_current_win()
				end
			end

			vim.cmd 'topleft 40vsplit'
			return vim.api.nvim_get_current_win()
		end

		neotest.setup {
			adapters = {
				require('neotest-golang') {
					warn_test_name_dupes = false,
				},
			},
			summary = {
				open = open_summary,
			},
		}

		vim.keymap.set('n', '<leader>tt', function()
			neotest.run.run()
		end, { desc = 'Test: run nearest' })

		vim.keymap.set('n', '<leader>tf', function()
			neotest.run.run(vim.fn.expand '%')
		end, { desc = 'Test: run current file' })

		vim.keymap.set('n', '<leader>tl', function()
			neotest.run.run_last()
		end, { desc = 'Test: run last' })

		vim.keymap.set('n', '<leader>ts', function()
			neotest.summary.toggle()
		end, { desc = 'Test: toggle summary' })

		vim.keymap.set('n', '<leader>tu', function()
			neotest.output.open {
				enter = true,
				auto_close = true,
			}
		end, { desc = 'Test: show output' })
	end,
}
