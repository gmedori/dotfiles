" We want to execute shell commands in bash
if &shell =~# 'fish$'
	set shell=bash
endif

set nocompatible
filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'VundleVim/Vundle.vim'
Plugin 'xolox/vim-misc'
Plugin 'xolox/vim-notes'
Plugin 'dag/vim-fish'
Plugin 'vimwiki/vimwiki'
Plugin 'gabrielelana/vim-markdown'
Plugin 'chriskempson/tomorrow-theme'
Plugin 'marciomazza/vim-brogrammer-theme'
Plugin 'keith/swift.vim'
Plugin 'jcf/vim-latex'
Plugin 'godlygeek/tabular'
Plugin 'scrooloose/nerdtree'
Plugin 'Lokaltog/vim-easymotion'
Plugin 'shawncplus/skittles_berry'
Plugin 'scrooloose/syntastic'
Plugin 'SirVer/ultisnips'
Plugin 'bling/vim-airline'
Plugin 'edkolev/tmuxline.vim'

call vundle#end()

"============== Ultisnips Setup ==============
let g:UltiSnipsExpandTrigger="<TAB>"
let g:UltiSnipsJumpForwardTrigger="<TAB>"
let g:UltiSnipsJumpBackwardTrigger="<S-TAB>"
let g:UltiSnipsEditSplit="vertical"

"============== Custom scripts ===============
source ~/.vim/after/syntaxcheck.vim

"============== airline setup ===============
let g:airline_powerline_fonts = 1
let g:airline_detect_modified=1

"============== Latex Stuff ===============
let g:tex_flavor='latex'

"============== Filetype stuff ===============
filetype plugin on
filetype indent on

"============== Script configs ===============
let NERDTreeMinimalUI=1
let NERDTreeDirArrows=1

"============== Vim Wiki configs ===============
let wiki = {}
let wiki.path = '~/vimwiki/'
let wiki.nested_syntaxes = {'python': 'python', 'c': 'c', 'sml': 'sml'}
let g:vimwiki_list = [wiki]

"============== Vim Notes Setup ===============
let g:notes_directories = ['~/notes/']

" Load custom settings
source ~/.vim/startup/color.vim
source ~/.vim/startup/settings.vim

" Show syntax highlighting groups for word under cursor
nmap <C-F> :call SynStack()<CR>
function! SynStack()
	if !exists("*synstack")
		return
	endif
	echo map(synstack(line('.'), col('.')), 'synIDattr(v:val, "name")')
endfunc

" This somehow fixes the cursor issue I was having. No more skinny cursor,
" Always block cursor now.
if exists('$TMUX')
	let &t_SI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=4\x7\<Esc>\\"
	let &t_EI = "\<Esc>Ptmux;\<Esc>\<Esc>]50;CursorShape=4\x7\<Esc>\\"
else
	let &t_SI = "\<Esc>]50;CursorShape=4\x7"
	let &t_EI = "\<Esc>]50;CursorShape=4\x7"
endif

"============== Custom Mappings ===============

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

" upper or lowercase the current word
nmap g^ gUiW
nmap gv guiW

" default to very magic
no / /\v

"I really hate that things don't auto-center
nmap G Gzz
nmap n nzz
nmap N Nzz
nmap } }zz
nmap { {zz

"quick pairs
"imap <leader>' ''<ESC>i
"imap <leader>" ""<ESC>i
"imap <leader>( ()<ESC>i
"imap <leader>[ []<ESC>i
imap {<CR> {<CR>}<ESC>O

" replace string contents with recently copied text
nmap <Leader>r" "_di"P
nmap <Leader>c" "_di"Pa
nmap <Leader>r' '_di'P
nmap <Leader>c' '_di'Pa


" Open an close NERDTree easily
nmap <Leader>> :NERDTree<CR>
nmap <Leader>< :NERDTreeClose<CR>

"Equalize splits
map <C-=> <C-W>=

"compile and view latex files.
autocmd Filetype tex,latex nmap <Leader>p :!pdflatex %<CR><CR>
autocmd Filetype tex,latex nmap <Leader><S-P> :!pdflatex %<CR>
autocmd Filetype tex,latex nmap <Leader>o :!open %<.pdf<CR><CR>

nnoremap <Space> :nohlsearch<CR>

"============== Custom Settings ===============
set tw=79
