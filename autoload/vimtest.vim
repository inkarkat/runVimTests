" TODO: summary
"
" DESCRIPTION:
" USAGE:
" INSTALLATION:
"   Put the script into your user or system VIM plugin directory (e.g.
"   ~/.vim/plugin). 

" DEPENDENCIES:
" CONFIGURATION:
" INTEGRATION:
" LIMITATIONS:
" ASSUMPTIONS:
" KNOWN PROBLEMS:
" TODO:
"
" Copyright: (C) 2009 by Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"	001	25-Jan-2009	file creation

function! vimtest#Quit()
    " If the message output has been processed, make sure that the modified
    " output is saved. 
    if expand('%') =~# '\.msgout$'
	update!
    endif

    if ! (exists('g:debug') && g:debug)
	quitall!
    endif
endfunction

function! vimtest#StartTap( sfile )
    call vimtap#Output(fnamemodify(a:sfile, ':p:r') . '.tap') 
endfunction
function! vimtest#SaveOut( sfile )
    execute 'saveas! ' . fnamemodify(a:sfile, ':p:r') . '.out'
endfunction

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
