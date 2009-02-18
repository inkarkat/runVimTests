" TODO: summary
"
" DESCRIPTION:
" USAGE:
" INSTALLATION:
"   Put the script into your user or system VIM plugin directory (e.g.
"   ~/.vim/plugin). 

" DEPENDENCIES:
"   - escapings.vim autoload script (for VIM 7.0/7.1). 
"
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
"	004	19-Feb-2009	Added vimtest#System() and vimtap#Error(), plus
"				a stub for vimtest#Skip(). 
"	003	09-Feb-2009	The *.out files are always written with
"				fileformat=unix to allow platform-independent
"				comparisons. 
"	002	06-Feb-2009	Renamed g:debug to g:runVimTests. 
"				Removed check for processed msgout output, this
"				is now done as a separate process with
"				'runVimMsgFilter.vim'. 
"				Now escaping saved *.out filespec. 
"				Passing of the test name is not optional, it is
"				can be determined automatically from
"				g:vimRunTest, if the test is run from within the
"				test framework. 
"	001	25-Jan-2009	file creation

function! vimtest#Quit()
    if ! (exists('g:runVimTests') && g:runVimTests =~# '\<debug\>')
	quitall!
    endif
endfunction
function! vimtest#Error( reason )
    " TODO: Implement. 
    call vimtest#Quit()
endfunction
function! vimtest#Skip( reason )
    " TODO: Implement. 
    call vimtest#Quit()
endfunction
" function! vimtest#SkipOut( reason )
" function! vimtest#SkipMsgout( reason )
" function! vimtest#SkipTap( reason )

function! vimtest#System( shellcmd )
    " In case the shellcmd is a batch file, the invocation via 'cmd.exe /c ...'
    " doesn't return the batch file's exit status. Since it's safe to invoke
    " all executables through 'cmd.exe /c call ...', we always interject this. 
    let l:shellcmd = (&shell =~? 'cmd\.exe$' ? 'call ' : '') . a:shellcmd

    let l:shelloutput = system(l:shellcmd)
    echo 'Executing shell command: ' . a:shellcmd
    echo l:shelloutput
    if v:shell_error
	echo printf('Execution failed with exit status %d, aborting test.', v:shell_error)
	call vimtest#Error(printf("Execution of '%s' failed with exit status %d.", a:shellcmd, v:shell_error))
    endif
endfunction

function! s:MakeFilename( arguments, extension )
    let l:testname = (len(a:arguments) > 0 ? a:arguments[0] : (exists('g:runVimTest') ? g:runVimTest : 'unknown'))
    return fnamemodify(l:testname, ':p:r') . a:extension
endfunction
function! vimtest#StartTap( ... )
    call vimtap#Output(s:MakeFilename(a:000, '.tap'))
endfunction
function! vimtest#SaveOut( ... )
    let l:outname = s:MakeFilename(a:000, '.out')
    if v:version >= 702
	execute 'saveas! ++ff=unix ' . fnameescape(l:outname)
    else
	execute 'saveas! ++ff=unix ' . escapings#fnameescape(l:outname)
    endif
endfunction

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
