if exists('g:loaded_simpleminimap') | finish | endif " prevent loading file twice

let s:save_cpo = &cpo " save user coptions
set cpo&vim " reset them to defaults

" get code-minimap file
" let g:gen_cmd = expand('<sfile>:p:h:h').'/bin/minimap_generator.sh'

" command to run our plugin
command! SimpleMinimapOpen lua require'simpleminimap'.open()
command! SimpleMinimapClose lua require'simpleminimap'.close()
autocmd! BufEnter * lua require'simpleminimap'.update()

let &cpo = s:save_cpo " and restore after
unlet s:save_cpo

let g:loaded_simpleminimap = 1

echo "simpleminimap loaded"

" echo expand('<sfile>:p:h:h:h').'/bin/minimap_generator.sh'


" if g:minimap_auto_start == 1
"     augroup MinimapAutoStart
"         au!
"         au BufWinEnter * Minimap
"         if g:minimap_auto_start_win_enter == 1
"             au WinEnter * Minimap
"         endif
"     augroup end
" endif
