" vimtest/features.vim: Testing feature checks for the runVimTests testing framework.
"
" DEPENDENCIES:
"
" Copyright: (C) 2011-2017 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>

function! vimtest#features#SupportsNormalWithCount()
    return v:version > 703 || v:version == 703 && has('patch100')
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
