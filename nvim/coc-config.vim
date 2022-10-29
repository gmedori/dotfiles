autocmd CursorHold * silent call CocActionAsync('highlight')

" Use <C-k> to trigger completion.
inoremap <silent><expr> <C-_> coc#refresh()

inoremap <silent><expr> <C-n> coc#pum#visible() ? coc#pum#next(1) : "\<C-n>"
inoremap <silent><expr> <C-p> coc#pum#visible() ? coc#pum#prev(1) : "\<C-p>"

