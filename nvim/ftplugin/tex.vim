NeomakeDisable
let g:vimtex_compiler_enabled=0
autocmd BufWritePost *.tex silent! !ltxbuild
