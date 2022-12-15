" Comma should be mapleader
let mapleader = ','

let $PAGER = ''

" Tell vim to use a 'normal' shell for executing commands.
if &shell =~# 'fish$'
    set shell=sh
endif

call plug#begin()

" For automatically inserting pairs of quotes, brackets, etc.
Plug 'jiangmiao/auto-pairs'

" For navigating my project structure in the way that I'm used to with IDEs
" Plug 'scrooloose/nerdtree'
Plug 'nvim-tree/nvim-tree.lua'

" For making pretty status bars
"Plug 'vim-airline/vim-airline'
Plug 'feline-nvim/feline.nvim'

" For pretty colors
Plug 'morhetz/gruvbox'

" For more pretty colors
Plug 'jonathanfilip/vim-lucius'

" For editing fish files
Plug 'dag/vim-fish'

" For linting stuff
Plug 'neomake/neomake'

" For writing latex, because it's better in nvim
Plug 'lervag/vimtex'

" For making things look pretty and formatted
Plug 'godlygeek/tabular'

" For no more accidental empty files
Plug 'EinfachToll/DidYouMean'

" For fuzzy file finding!
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" For git stuff from within vim
Plug 'tpope/vim-fugitive'

" For changing surrounding characters
Plug 'tpope/vim-surround'

" For moar color
Plug 'KeitaNakamura/neodark.vim'

" For easy viewing git status in vim
Plug 'airblade/vim-gitgutter'

" For moar moar color
Plug 'tyrannicaltoucan/vim-deep-space'

" For strong Golang support
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }

" For a fancy start screen
Plug 'mhinz/vim-startify'

" For a simpler color theme
Plug 'rakr/vim-two-firewatch'

" For da bad wolf
Plug 'sjl/badwolf'

" For better markdown highlighting
Plug 'plasticboy/vim-markdown'
" Plug 'tpope/vim-markdown'

" For VimDeck syntax highlighting
Plug 'vim-scripts/SyntaxRange'
Plug 'vim-scripts/ingo-library'

" For viewing perldocs
Plug 'hotchpotch/perldoc-vim'

" For decent autocomplete
Plug 'neoclide/coc.nvim', {'branch': 'release'}

" For Brewfile editing
Plug 'bfontaine/Brewfile.vim'

" For commenting stuff out
Plug 'tpope/vim-commentary'

" For auto-inserting end in Ruby
Plug 'tpope/vim-endwise'

" For Swift syntax highlighting
Plug 'keith/swift.vim'

" For snippets!
Plug 'L3MON4D3/LuaSnip', {'tag': 'v1.*'}

call plug#end()

"============= LuaSnip Setup ==============
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
lua << EOF
require("luasnip.loaders.from_snipmate").lazy_load()
EOF

"============= Git Commit Setup ==============
au FileType gitcommit setlocal textwidth=0

"=============-Go Setup ==============
let g:go_fmt_command = "goimports"    " Run goimports along gofmt on each save
let g:go_auto_type_info = 1           " Automatically get signature/type info for object under cursor


"============== Vim-Markdown Setup ==============
let g:vim_markdown_new_list_item_indent = 2

"============== Latex Stuff ===============
let g:tex_flavor='latex'
let g:tex_conceal=""

"============== Colorscheme Configs ===============
" packadd! dracula_pro
" let g:dracula_colorterm = 1
" colorscheme dracula_pro_blade
colorscheme badwolf

"============== DevIcons Configs ===============
function! MyFiletype()
  return winwidth(0) > 70 ? (strlen(&filetype) ? &filetype . ' ' . WebDevIconsGetFileTypeSymbol() : 'no ft') : ''
endfunction

function! MyFileformat()
  return winwidth(0) > 70 ? (&fileformat . ' ' . WebDevIconsGetFileFormatSymbol()) : ''
endfunction

"============== Vim-Airline Configs ===============
" let g:airline_left_sep=''
" let g:airline_right_sep=''
" let g:airline#extensions#tabline#enabled = 1
" let g:airline#extensions#tabline#fnamemod = ':t'

"============== Vim-Airline Configs ===============
set termguicolors " needs to come before feline config
lua << EOF
require('feline').setup()
EOF


""============== Neomake Configs ===============
call neomake#configure#automake('w')
let g:neomake_python_enabled_makers = ['pylint']
let g:neomake_python_pylint_maker = {
  \ 'args': [
  \ '-d', 'C0114',
  \ '-f', 'text',
  \ '--msg-template="{path}:{line}:{column}:{C}: [{symbol}] {msg}"',
  \ '-r', 'n'
  \ ],
  \ 'errorformat':
  \ '%A%f:%l:%c:%t: %m,' .
  \ '%A%f:%l: %m,' .
  \ '%A%f:(%l): %m,' .
  \ '%-Z%p^%.%#,' .
  \ '%-G%.%#',
  \ }

"============== Color Inspector ===============
nmap <C-F> :call <SID>SymbStack()<CR>
function! <SID>SymbStack()
    if !exists("*synstack")
    return
  endif
  echo map(synstack(line('.'), col('.')), 'synIDattr(v:val, "name")')
endfunction

"============== Ripgrep Find ===============
command! -bang -nargs=* Find call fzf#vim#grep('rg --column --line-number --no-heading --fixed-strings --ignore-case --no-ignore --hidden --follow --glob "!.git/*" --color "always" '.shellescape(<q-args>), 1, <bang>0)

"=======================================
"============== Mappings ===============
"=======================================

" Unmap the arrow keys
no <down> ddp
no <left> <Nop>
no <right> <Nop>
no <up> ddkP
ino <down> <Nop>
ino <left> <Nop>
ino <right> <Nop>
ino <up> <Nop>
vno <down> <Nop>
vno <left> <Nop>
vno <right> <Nop>
vno <up> <Nop>

" default to very magic
no / /\v

"I really hate that things don't auto-center
nmap G Gzz
nmap n nzz
nmap N Nzz
nmap } }zz
nmap { {zz

" Open an close NERDTree easily
" nmap <Leader>> :NERDTree<CR>
" nmap <Leader>< :NERDTreeClose<CR>

" fix file indentation
nmap <Leader>== gg=G''

"Equalize splits
map <C-=> <C-W>=

"Move between buffers easily
nmap <Leader><right> :bn<CR>
nmap <Leader><left> :bp<CR>

nnoremap <Space> :nohlsearch<CR>

"fugitive shortcuts
nmap <Leader>gs :Gstatus<CR>

" QuickFix and Location window shortcuts
no <Leader>ll :lopen<CR>
no <Leader>qq :copen<CR>

" Search and replace under text
nnoremap <Leader>s :%s/\<<C-r><C-w>\>/

" Open file quickly with fzf
nnoremap <Leader>o :Files<CR>

"=======================================
"============== Settings ===============
"=======================================

" Enables mouse in vim
set mouse=a

" Makes cursor line visible
set cursorline

" Allows searching before enter key is pressed
set incsearch

" Allows fancy menu which you can tab thru when executing commands
set wildmenu

" Enable syntax... duh
syntax enable
filetype plugin indent on

" Remove the col limit on searching for syntax errors
set synmaxcol=0

" Modify messages that are displayed. Hit up the help files for this one.
set shortmess=aAIsT

" Let's see dem relative line numbers
set relativenumber
set number

" Visualize whitespace
set list listchars=tab:› ,trail:·,extends:>,precedes:<

" TAB MADNESS
set tabstop=4 softtabstop=4 shiftwidth=4 expandtab

" Creates the dropdown menu for autocompletion
" set completeopt=menu

" New splits should be created to the right and down.
set splitbelow
set splitright

" Make sure that we're always using utf8 encoding
set encoding=utf-8

" Center the damn cursor
" let &scrolloff=999

" Recursive search for files
set path+=**

" See commands as you're inputting them
set showcmd

" Wider text width
set tw=120

" Use ripgrep for grep
set grepprg=rg\ --vimgrep\ --no-heading\ --smart-case

" Folding is stupid.
set nofoldenable

" Configure coc.vim
source $HOME/.config/nvim/coc-config.vim

" autocommands
au BufNewFile,BufRead *.gitconfig setf gitconfig

" Nvim-Tree setup
lua << EOF
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
require("nvim-tree").setup()
EOF

nmap <Leader>> :NvimTreeOpen<CR>
nmap <Leader>< :NvimTreeClose<CR>
