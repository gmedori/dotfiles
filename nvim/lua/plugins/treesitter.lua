return { -- Highlight, edit, and navigate code
	'nvim-treesitter/nvim-treesitter',
	branch = 'main',
	build = ':TSUpdate',
	-- [[ Configure Treesitter ]] See `:help nvim-treesitter`
	--
	-- NOTE: This is the `main` branch of nvim-treesitter -- the maintained rewrite
	-- required for Neovim 0.11+/0.12. The old `master` branch is frozen and does
	-- not support 0.12 (its query predicates crash on LSP hover, diffs, etc.).
	-- The `main` branch has no `opts`/`ensure_installed`/`highlight` table: you
	-- install parsers explicitly and enable highlighting per-buffer.
	--
	-- HEADS UP: nvim-treesitter itself appears to be winding down / abandoned, so
	-- this may eventually need migrating to the `neovim-treesitter` fork instead.
	config = function()
		local languages = {
			'bash',
			'c',
			'cmake',
			'diff',
			'go',
			'html',
			'lua',
			'luadoc',
			'markdown',
			'markdown_inline',
			'query',
			'swift',
			'vim',
			'vimdoc',
		}

		-- Install (and update on :TSUpdate) the parsers we care about.
		require('nvim-treesitter').install(languages)

		-- Enable treesitter highlighting + indentation for any buffer whose
		-- filetype has a parser installed. pcall guards filetypes without one.
		vim.api.nvim_create_autocmd('FileType', {
			callback = function(args)
				if pcall(vim.treesitter.start, args.buf) then
					vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end
			end,
		})
	end,
}
