" Comma should be mapleader
let mapleader = ','

" Tell vim to use a 'normal' shell for executing commands.
if &shell =~# 'fish$'
	set shell=sh
endif

call plug#begin()

" For automatically inserting pairs of quotes, brackets, etc.
Plug 'jiangmiao/auto-pairs'

" For keeping my work (and life) organized
Plug 'vimwiki/vimwiki'

" For navigating my project structure in the way that I'm used to with IDEs
Plug 'scrooloose/nerdtree'

" For making pretty status bars
Plug 'vim-airline/vim-airline'

" For pretty colors
Plug 'morhetz/gruvbox'

" For more pretty colors
Plug 'jonathanfilip/vim-lucius'

" For pretty glyphs
Plug 'ryanoasis/vim-devicons'

" For editing fish files
Plug 'dag/vim-fish'

" For linting stuff
Plug 'neomake/neomake'

" For writing latex, because it's better in nvim
Plug 'lervag/vimtex'

" For snippets. Because snippets.
Plug 'Shougo/neosnippet'

" For making things look pretty and formatted
Plug 'godlygeek/tabular'

" For no more accidental empty files
Plug 'EinfachToll/DidYouMean'

" For knowing wtf I'm doing with everything
Plug 'rizzatti/dash.vim'

" For fuzzy file finding!
Plug '/usr/local/opt/fzf' | Plug 'junegunn/fzf.vim'

" For git stuff from within vim
Plug 'tpope/vim-fugitive'

" For KOTLIN
Plug 'udalov/kotlin-vim'

" For pretty tmux colors
Plug 'edkolev/tmuxline.vim'

call plug#end()

"============== Deoplete Setup ==============
let g:deoplete#enable_at_startup = 1

"============== Neosnippet Setup ==============
let g:neosnippet#snippets_directory = '~/.config/nvim/snippets'
let g:neosnippet#disable_runtime_snippets = { '_' : 1, }

imap <expr><TAB> neosnippet#expandable_or_jumpable() ? "\<Plug>(neosnippet_expand_or_jump)" : "\<TAB>"
smap <expr><TAB> neosnippet#expandable_or_jumpable() ? "\<Plug>(neosnippet_expand_or_jump)" : "\<TAB>"

"============== Latex Stuff ===============
let g:tex_flavor='latex'
let g:tex_conceal=""

"============== Vim Wiki configs ===============
let wiki = {}
let wiki.path = '$HOME/code/wiki/vimwiki'
let wiki.template_path = '$HOME/code/wiki/vimwiki/templates'
let wiki.template_default = 'default'
let wiki.template_ext = '.html'
let wiki.nested_syntaxes = {'python': 'python', 'c': 'c', 'sml': 'sml', 'markdown': 'markdown', 'bash': 'bash', 'text': 'text'}
let g:vimwiki_list = [wiki]
let g:vimwiki_valid_html_tags = 'p,blockquote,span'
"let g:vimwiki_conceallevel=0

"============== Gruvbox Configs ===============
colorscheme gruvbox
set background=dark

"============== DevIcons Configs ===============
function! MyFiletype()
  return winwidth(0) > 70 ? (strlen(&filetype) ? &filetype . ' ' . WebDevIconsGetFileTypeSymbol() : 'no ft') : ''
endfunction

function! MyFileformat()
  return winwidth(0) > 70 ? (&fileformat . ' ' . WebDevIconsGetFileFormatSymbol()) : ''
endfunction

"============== Vim-Airline Configs ===============
let g:airline_left_sep=''
let g:airline_right_sep=''
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#fnamemod = ':t'

"============== Neomake Configs ===============
autocmd! BufWritePost,BufEnter * Neomake
let g:neomake_warning_sign = {
	\ 'text': '!',
	\ 'texthl': 'GruvboxYellowBold'
	\ }
let g:neomake_error_sign = {
	\ 'text': 'X',
	\ 'texthl': 'GruvboxRedBold'
	\ }

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
nmap <Leader>> :NERDTree<CR>
nmap <Leader>< :NERDTreeClose<CR>

" fix file indentation
nmap <Leader>== gg=G''

"Equalize splits
map <C-=> <C-W>=

"compile and view latex files.
autocmd Filetype tex,latex nmap <Leader>p :!pdflatex %<CR><CR>
autocmd Filetype tex,latex nmap <Leader><S-P> :!pdflatex %<CR>
autocmd Filetype tex,latex nmap <Leader>o :!open %<.pdf<CR><CR>
autocmd Filetype tex,latex nmap <Leader>mk :!make clean pdf<CR>

nnoremap <Space> :nohlsearch<CR>

"fugitive shortcuts
nmap <Leader>gs :Gstatus<CR>

"=======================================
"============== Settings ===============
"=======================================


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
set list listchars=tab:› ,trail:-,extends:>,precedes:<,eol:¬

" TAB MADNESS
set tabstop=4 softtabstop=4 shiftwidth=4 noexpandtab

" Creates the dropdown menu for autocompletion
set completeopt=menu

" New splits should be created to the right and down.
set splitbelow
set splitright

" Make sure that we're always using utf8 encoding
set encoding=utf-8

" Center the damn cursor
let &scrolloff=999

" Enable true color support
set termguicolors

" Recursive search for files
set path+=**

" See commands as you're inputting them
set showcmd
