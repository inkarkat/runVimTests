" vimtest.vim: General utility functions for the runVimTests testing framework. 
"
" DEPENDENCIES:
"   - Requires Vim 7.0 or higher.  
"   - escapings.vim autoload script (for Vim 7.0/7.1). 
"
" Copyright: (C) 2009-2010 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"   1.15.011	07-Oct-2010	ENH: Added vimtest#ErrorAndQuitIf(), because
"				it's a common use case, too. 
"   1.15.010	03-Oct-2010	ENH: Added vimtest#ErrorAndQuit(), because it's
"				a common use case. 
"   1.14.009	10-Jul-2009	BF: vimtest#System() didn't abort via
"				vimtest#Quit() on shell errors. 
"				Added optional isIgnoreErrors argument to
"				vimtest#System(). 
"   1.10.008	08-Mar-2009	Split vimtest#SkipAndQuit() into vimtest#Skip(),
"				a general, single-purpose function, and
"				vimtest#SkipAndQuitIf(), a special (but
"				often-used) convenience function. 
"   1.10.007	05-Mar-2009	ENH: Added vimtest#BailOut(), vimtest#Error(),
"				and vimtest#Skip...() functions. 
"   1.00.006	02-Mar-2009	Adapted to VimTAP 0.3: Changed function name to
"				vimtap#SetOutputFile() and added
"				vimtap#FlushOutput(). 
"	005	28-Feb-2009	BF: Improved insertion of 'call' in
"				vimtest#System(). 
"	004	19-Feb-2009	Added vimtest#System(), vimtap#Error() and
"				vimtest#RequestInput(), plus a stub for
"				vimtest#Skip(). 
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
    if s:isTap
	call vimtap#FlushOutput()
    endif

    if ! (exists('g:runVimTests') && g:runVimTests =~# '\<debug\>')
	quitall!
    endif
endfunction

function! s:SignalToDriver( signal, reason )
    echo 'runVimTests: ' . a:signal .  (empty(a:reason) ? '' : ' ' . a:reason)
endfunction
function! vimtest#BailOut( reason )
    call s:SignalToDriver('BAILOUT!', a:reason)
    call vimtest#Quit()
endfunction
function! vimtest#Error( reason )
    call s:SignalToDriver('ERROR', a:reason)
endfunction
function! vimtest#ErrorAndQuit( reason )
    call vimtest#Error(a:reason)
    call vimtest#Quit()
endfunction
function! vimtest#ErrorAndQuitIf( condition, reason )
    if a:condition
	call vimtest#ErrorAndQuit(a:reason)
    endif
endfunction
function! vimtest#Skip( reason )
    call s:SignalToDriver('SKIP', a:reason)
endfunction
function! vimtest#SkipOut( reason )
    call s:SignalToDriver('SKIP(out)', a:reason)
endfunction
function! vimtest#SkipMsgout( reason )
    call s:SignalToDriver('SKIP(msgout)', a:reason)
endfunction
function! vimtest#SkipTap( reason )
    call s:SignalToDriver('SKIP(tap)', a:reason)
endfunction
function! vimtest#SkipAndQuitIf( condition, reason )
    if a:condition
	call vimtest#Skip(a:reason)
	call vimtest#Quit()
    endif
endfunction

function! vimtest#System( shellcmd, ... )
    let l:shellcmd = a:shellcmd
    let l:isIgnoreErrors = (a:0 && a:1)
    if &shell =~? 'cmd\.exe$'
	" In case the shellcmd is a batch file, the invocation via 'cmd.exe /c ...'
	" doesn't return the batch file's exit status. Since it's safe to invoke
	" all executables through 'cmd.exe /c call ...', we always interject
	" this, unless it's already there. 
	" We need to do a careful replacement here, the entire shell command may
	" be enclosed in double quotes, so that command lists (e.g. cmd1 &&
	" cmd2) work. 
	if l:shellcmd !~# '^\("\)\?call .*\1$'
	    let l:shellcmd = substitute(l:shellcmd, '^\("\)\?\zs\ze.*\1$', 'call ', '')
	endif
    endif

    let l:shelloutput = system(l:shellcmd)
    echo 'Executing shell command: ' . a:shellcmd
    echo l:shelloutput
    if v:shell_error && ! l:isIgnoreErrors
	echo printf('Execution failed with exit status %d, aborting test.', v:shell_error)
	call vimtest#Error(printf("Execution of '%s' failed with exit status %d.", a:shellcmd, v:shell_error))
	call vimtest#Quit()
    endif
    return (! v:shell_error)
endfunction

function! s:MakeFilename( arguments, extension )
    let l:testname = (len(a:arguments) > 0 ? a:arguments[0] : (exists('g:runVimTest') ? g:runVimTest : 'unknown'))
    return fnamemodify(l:testname, ':p:r') . a:extension
endfunction
let s:isTap = 0
function! vimtest#StartTap( ... )
    call vimtap#SetOutputFile(s:MakeFilename(a:000, '.tap'))
    let s:isTap = 1
endfunction
function! vimtest#SaveOut( ... )
    let l:outname = s:MakeFilename(a:000, '.out')
    if exists('*fnameescape')
	execute 'saveas! ++ff=unix ' . fnameescape(l:outname)
    else
	execute 'saveas! ++ff=unix ' . escapings#fnameescape(l:outname)
    endif
endfunction

function! vimtest#RequestInput( input )
    echohl Search
    echo "User: PLEASE PRESS '"
    echohl ErrorMsg
    echon a:input
    echohl Search
    echon "'"
    echohl None
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
