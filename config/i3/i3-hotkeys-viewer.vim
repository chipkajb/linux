set nomodifiable nowrap scrolloff=4 sidescrolloff=4 cursorline number relativenumber signcolumn=no
set listchars=tab:»·,trail:· list
hi LineNr ctermfg=243 ctermbg=NONE
hi CursorLine ctermbg=236 cterm=NONE
hi NonText ctermfg=243
nnoremap <silent> <Esc> :qa!<CR>
nnoremap <silent> q :qa!<CR>
nnoremap <silent> h zh
nnoremap <silent> l zl
nnoremap <silent> H gg
nnoremap <silent> L G
nnoremap <silent> <C-d> 15j
nnoremap <silent> <C-u> 15k
autocmd VimEnter * normal! gg
