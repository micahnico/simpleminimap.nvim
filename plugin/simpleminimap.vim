if exists('g:loaded_simpleminimap') | finish | endif " prevent loading file twice

if !executable('code-minimap')
  echom 'code-minimap must be installed for simpleminimap.nvim to work'
  finish
endif

let s:save_cpo = &cpo " save user coptions
set cpo&vim " reset them to defaults

" commands & autocmds
command! SimpleMinimapOpen lua require'simpleminimap'.open()
command! SimpleMinimapClose lua require'simpleminimap'.close()

autocmd! BufEnter * lua require'simpleminimap'.on_update()
autocmd! BufWritePost,VimResized * lua require'simpleminimap'.on_update(true)
autocmd! CursorMoved,CursorMovedI,FocusGained * lua require'simpleminimap'.on_move()
autocmd! QuitPre * lua require'simpleminimap'.on_quit()

let &cpo = s:save_cpo " and restore after
unlet s:save_cpo

let g:loaded_simpleminimap = 1
