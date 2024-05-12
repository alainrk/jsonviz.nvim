" prevent loading file twice
if exists('g:loaded_jsonviz') | finish | endif

" save user coptions
let s:save_cpo = &cpo

" reset them to defaults
set cpo&vim

" command to run our plugin
command! JsonViz lua require'jsonviz'.jsonviz()

" and restore after
let &cpo = s:save_cpo
unlet s:save_cpo

let g:loaded_jsonviz = 1
