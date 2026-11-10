-- Indent `case` one level deeper than `switch`.
-- nvim-treesitter's swift indents.scm marks the first child of `switch_entry`
-- as @indent.branch, dedenting cases back to the switch column. Strip that
-- rule and re-register the query. String surgery is needed because there is
-- no clean per-rule override API yet — see
-- https://github.com/neovim/neovim/issues/23373
local files = vim.api.nvim_get_runtime_file('queries/swift/indents.scm', true)
if #files > 0 then
	local src = table.concat(vim.fn.readfile(files[1]), '\n')
	src = src:gsub('%(switch_entry%s*%.%s*_%s*@indent%.branch%)', '')
	vim.treesitter.query.set('swift', 'indents', src)
end
