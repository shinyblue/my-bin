" Vim filetype plugin file
" Language:	text
" Maintainer:	Rich
" Last Changed: 23 Jul 2004

if exists("b:did_ftplugin") | finish | endif
let b:did_ftplugin = 1

" Make sure the continuation lines below do not cause problems in
" compatibility mode.
let s:save_cpo = &cpo
set cpo-=C

" rich's stuff starts here
setlocal expandtab
setlocal tabstop=4
setlocal textwidth=64
setlocal autoindent
setlocal formatoptions+=awn

" rich's stuff ends here

" Undo the stuff we changed.
let b:undo_ftplugin = "setlocal commentstring<"
    \	" | unlet! b:match_ignorecase b:match_skip b:match_words b:browsefilter"

" Restore the saved compatibility options.
let &cpo = s:save_cpo
