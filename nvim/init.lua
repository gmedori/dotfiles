require('plugins')

-- Comma should be mapleader
vim.g.mapleader = ","

-- Vim needs a more POSIX compatible shell than fish for certain functionality to work, such as :%!,
-- compressed help pages and many third-party plugins.

vim.cmd("if &shell =~# 'fish$' | set shell=sh | endif")

---------------- LuaSnip Setup ----------------
vim.cmd([[
" press <Tab> to expand or jump in a snippet. These can also be mapped separately
" via <Plug>luasnip-expand-snippet and <Plug>luasnip-jump-next.
imap <silent><expr> <Tab> luasnip#expand_or_jumpable() ? '<Plug>luasnip-expand-or-jump' : '<Tab>' 

" -1 for jumping backwards.
inoremap <silent> <S-Tab> <cmd>lua require'luasnip'.jump(-1)<Cr>
snoremap <silent> <Tab> <cmd>lua require('luasnip').jump(1)<Cr>
snoremap <silent> <S-Tab> <cmd>lua require('luasnip').jump(-1)<Cr>

" For changing choices in choiceNodes (not strictly necessary for a basic setup).
imap <silent><expr> <C-E> luasnip#choice_active() ? '<Plug>luasnip-next-choice' : '<C-E>'
smap <silent><expr> <C-E> luasnip#choice_active() ? '<Plug>luasnip-next-choice' : '<C-E>'
]])
require("luasnip.loaders.from_snipmate").lazy_load()

---------------- Vim-Markdown Setup ----------------
vim.g.vim_markdown_new_list_item_indent = 2

---------------- Colorscheme Setup ----------------
vim.cmd("colorscheme badwolf")

---------------- Vim-Tree Setup ----------------
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.o.termguicolors = true
require("nvim-tree").setup({git = { ignore = false} })

------------------------------------------------
------------------- Mappings -------------------
------------------------------------------------

-- Unmap the arrow keys
vim.keymap.set("n"  , "<down>"  , "ddp")
vim.keymap.set("n"  , "<left>"  , "<Nop>")
vim.keymap.set("n"  , "<right>" , "<Nop>")
vim.keymap.set("n"  , "<up>"    , "ddkP")
vim.keymap.set("i" , "<down>"  , "<Nop>")
vim.keymap.set("i" , "<left>"  , "<Nop>")
vim.keymap.set("i" , "<right>" , "<Nop>")
vim.keymap.set("i" , "<up>"    , "<Nop>")
vim.keymap.set("v" , "<down>"  , "<Nop>")
vim.keymap.set("v" , "<left>"  , "<Nop>")
vim.keymap.set("v" , "<right>" , "<Nop>")
vim.keymap.set("v" , "<up>"    , "<Nop>")

-- Default to very magic
vim.keymap.set("n", "/", "/\\v")

-- Auto-center movement commands
vim.keymap.set("n", "G", "Gzz")
vim.keymap.set("n", "n", "nzz")
vim.keymap.set("n", "N", "Nzz")
vim.keymap.set("n", "}", "}zz")
vim.keymap.set("n", "{", "{zz")

-- Search and replace under text
vim.keymap.set("n", "<Leader>s", ":%s/\\<<C-r><C-w>\\>/")

-- Open and close sidebar
vim.keymap.set("n", "<Leader>>", ":NvimTreeOpen<CR>")
vim.keymap.set("n", "<Leader><", ":NvimTreeClose<CR>")

------------------------------------------------
------------------- Settings -------------------
------------------------------------------------

-- Enables mouse in vim
vim.o.mouse = "a"

-- Makes cursor line visible
vim.o.cursorline = true

-- Allows fancy menu which you can tab thru when executing commands
vim.o.wildmenu = true

-- Enable syntax... duh
vim.cmd("syntax enable")
vim.cmd("filetype plugin indent on")

-- Remove the col limit on searching for syntax errors
vim.o.synmaxcol = 0

-- Modify messages that are displayed. Hit up the help files for this one.
vim.o.shortmess = "aAIsT"

-- Let's see dem relative line numbers
vim.o.relativenumber = true
vim.o.number = true

-- Visualize whitespace
vim.o.list = "listchars=tab:› ,trail:·,extends:>,precedes:<"

-- TAB MADNESS
vim.o.tabstop = 4 
vim.o.softtabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true

-- New splits should be created to the right and down.
vim.o.splitbelow = true
vim.o.splitright = true

-- Make sure that we're always using utf8 encoding
vim.o.encoding = "utf-8"

-- Recursive search for files
vim.o.path = vim.o.path .. "**"

-- See commands as you're inputting them
vim.o.showcmd = true

-- Wider text width, 0 is no limit
vim.o.textwidth = 0

-- Use ripgrep for grep
vim.o.grepprg = "rg --vimgrep --no-heading --smart-case"

-- Folding is stupid.
vim.o.foldenable = false
------------------------------------------------
----------------- Plugin Config ----------------
------------------------------------------------

require("lualine").setup {
    options = {
        theme = "ayu_mirage"
    }
}
