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
"	002	06-Feb-2009	Renamed g:debug to g:runVimTests. 
"				Removed check for processed msgout output, this
"				is now done as a separate process with
"				'runVimMsgFilter.vim'. 
"				Now escaping saved *.out filespec. 
"	001	25-Jan-2009	file creation

function! vimtest#Quit()
    if ! (exists('g:runVimTests') && g:runVimTests =~# '\<debug\>')
	quitall!
    endif
endfunction

function! vimtest#StartTap( sfile )
    call vimtap#Output(fnamemodify(a:sfile, ':p:r') . '.tap') 
endfunction
function! vimtest#SaveOut( sfile )
    if v:version >= 702
	execute 'saveas! ' . fnameescape(fnamemodify(a:sfile, ':p:r') . '.out')
    else
	execute 'saveas! ' . escapings#fnameescape(fnamemodify(a:sfile, ':p:r') . '.out')
    endif
endfunction

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
