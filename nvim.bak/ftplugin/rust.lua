-- Formatting commands
vim.keymap.set("n", "<C-f>", ":RustFmt<CR>")
vim.keymap.set("i", "<C-f>", "<ESC>:RustFmt<CR>")

-- RustLsp commands

vim.keymap.set("n", "<leader>ca", ":RustLsp codeAction<CR>")
