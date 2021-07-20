if exists('g:loaded_simpleminimap') | finish | endif " prevent loading file twice

let s:save_cpo = &cpo " save user coptions
set cpo&vim " reset them to defaults

" commands & autocmds
command! SimpleMinimapOpen lua require'simpleminimap'.open()
command! SimpleMinimapClose lua require'simpleminimap'.close()
autocmd! BufEnter * lua require'simpleminimap'.on_buf_enter()
autocmd! CursorMoved,CursorMovedI * lua require'simpleminimap'.on_move()

let &cpo = s:save_cpo " and restore after
unlet s:save_cpo

let g:loaded_simpleminimap = 1
