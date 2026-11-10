local golangci_config_files = { '.golangci.yml', '.golangci.yaml', '.golangci.toml', '.golangci.json' }

return {
	'stevearc/conform.nvim',
	opts = {
		-- Add a filetype here to enable formatting on save.
		formatters_by_ft = {
			go = function(bufnr)
				if vim.fs.root(bufnr, golangci_config_files) then
					return { 'golangci-lint' }
				end
				return { 'goimports' }
			end,
			-- lua = { 'stylua' },
		},
		formatters = {
			['golangci-lint'] = {
				-- Run against a temporary file beside the source file so package
				-- imports, generated-file detection, and path exclusions still work.
				args = { 'fmt', '$FILENAME' },
				stdin = false,
				tmpfile_format = 'conform.$RANDOM.$FILENAME',
				cwd = function(_, ctx)
					return vim.fs.root(ctx.filename, golangci_config_files)
				end,
				require_cwd = true,
			},
		},
		format_on_save = function(bufnr)
			local filetype = vim.bo[bufnr].filetype
			if require('conform').formatters_by_ft[filetype] then
				return {
					timeout_ms = 3000,
					lsp_format = 'never',
				}
			end
		end,
	},
}
