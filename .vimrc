set nocompatible
filetype off

set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()

Plugin 'scrooloose/nerdtree'
Plugin 'Lokaltog/vim-easymotion'
Plugin 'shawncplus/skittles_berry'
Plugin 'scrooloose/syntastic'
Plugin 'SirVer/ultisnips'
Plugin 'bling/vim-airline'
Plugin 'edkolev/tmuxline.vim'

call vundle#end()

"============== Ultisnips Setup ==============
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<tab>"
let g:UltiSnipsJumpBackwardTrigger="<s-tab>"
let g:UltiSnipsEditSplit="vertical"

"============== Custom scripts ===============
source ~/.vim/after/syntaxcheck.vim

"============== airline setup ===============
let g:airline_powerline_fonts = 1
  let g:airline_detect_modified=1

"============== Filetype stuff ===============
filetype plugin on
filetype indent on

"============== Script configs ===============
let NERDTreeMinimalUI=1
let NERDTreeDirArrows=1

" Load custom settings
source ~/.vim/startup/color.vim
source ~/.vim/startup/mappings.vim
source ~/.vim/startup/settings.vim
