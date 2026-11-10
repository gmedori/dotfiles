-- alpha-nvim provides a nice start screen when launching vim without a file argument
return {
	'goolord/alpha-nvim',
	dependencies = { 'nvim-tree/nvim-web-devicons' },
	event = 'VimEnter',
	config = function()
		local alpha = require('alpha')
		local dashboard = require('alpha.themes.dashboard')

		-- ASCII art header
		dashboard.section.header.val = {
			[[                                                    ]],
			[[ ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ]],
			[[ ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ]],
			[[ ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ]],
			[[ ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ]],
			[[ ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ]],
			[[ ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ]],
			[[                                                    ]],
		}

		-- Italic highlight for shortcut keys (inherits color from colorscheme)
		local function_hl = vim.api.nvim_get_hl(0, { name = 'Function', link = false })
		vim.api.nvim_set_hl(0, 'AlphaShortcut', { italic = true, fg = function_hl.fg })

		-- Quick actions
		local function button(sc, txt, keybind)
			local btn = dashboard.button(sc, txt, keybind)
			btn.opts.cursor = 0
			btn.opts.hl_shortcut = 'AlphaShortcut'
			return btn
		end

		dashboard.section.buttons.val = {
			button('f', '  Find file', ':Telescope find_files<CR>'),
			button('r', '  Recent files', ':Telescope oldfiles<CR>'),
			button('g', '  Find text', ':Telescope live_grep<CR>'),
			button('n', '  New file', ':enew<CR>'),
			button('q', '  Quit', ':qa<CR>'),
		}

		-- Footer
		dashboard.section.footer.val = ''

		-- Layout
		dashboard.config.layout = {
			{ type = 'padding', val = 4 },
			dashboard.section.header,
			{ type = 'padding', val = 2 },
			dashboard.section.buttons,
			{ type = 'padding', val = 1 },
			dashboard.section.footer,
		}

		alpha.setup(dashboard.config)

		-- Disable folding on alpha buffer
		vim.cmd([[autocmd FileType alpha setlocal nofoldenable]])
	end,
}
