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

" Because it's pretty
Plug 'itchyny/lightline.vim'
Plug 'edkolev/tmuxline.vim'

" For pretty colors
Plug 'morhetz/gruvbox'

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

" For seeing all the different buffers, because fuck tabs (I think)
Plug 'bling/vim-bufferline'

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

"============== Lightline Configs ===============
let g:lightline = {
			\ 'active': {
			\	'left': [ [ 'mode', 'paste' ], [ 'filename' ], [ 'bufferline' ] ],
			\ },
			\ 'component': {
			\   'bufferline': '%{bufferline#refresh_status()}%{g:bufferline_status_info.before . g:bufferline_status_info.current . g:bufferline_status_info.after}'
			\ },
			\ 'colorscheme': 'gruvbox',
			\ 'component_function': {
			\   'filetype': 'MyFiletype',
			\   'fileformat': 'MyFileformat',
			\ }
			\ }

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

nnoremap <Space> :nohlsearch<CR>

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
