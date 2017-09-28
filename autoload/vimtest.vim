" vimtest.vim: General utility functions for the runVimTests testing framework.
"
" DEPENDENCIES:
"   - Requires Vim 7.0 or higher.
"   - ingo/compat.vim autoload script (for Vim 7.0/7.1)
"
" Copyright: (C) 2009-2017 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>

function! vimtest#Quit()
    if s:isTap
	call vimtap#FlushOutput()
    endif

    if exists('g:runVimTests') && g:runVimTests !~# '\<debug\>'
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
function! s:fnameescape( filename )
    if exists('*fnameescape')
	return fnameescape(a:filename)
    else
	return ingo#compat#fnameescape(a:filename)
    endif
endfunction
function! vimtest#SaveOut( ... )
    let l:outname = s:MakeFilename(a:000, '.out')
    execute 'saveas! ++ff=unix ' . s:fnameescape(l:outname)
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

function! vimtest#AddDependency( name )
    let l:defaultBaseDirspec = expand(has('dos16') || has('dos32') || has('win95') || has('win32') || has('win64') ? '~\vimfiles' : '~/.vim')
    let l:baseDirspec = (empty($RUNVIMTESTS_DEPENDENCY_BASE_DIRSPEC) ? l:defaultBaseDirspec : $RUNVIMTESTS_DEPENDENCY_BASE_DIRSPEC)

    let l:dirspec = finddir(a:name, l:baseDirspec . '/**')
    if empty(l:dirspec)
	call vimtest#BailOut(printf('Dependency %s not found under %s', a:name, l:baseDirspec))
    endif

    if stridx(',' . &runtimepath . ',', ',' . l:dirspec . ',') == -1
	let &runtimepath = l:dirspec . ',' . &runtimepath . ',' . l:dirspec . '/after'

	" Source any plugin scripts, but only from the added directory (and
	" after directory).
	let l:pluginScripts = split(globpath(l:dirspec, 'plugin/*.vim'), '\n') + split(globpath(l:dirspec, 'plugin/*/*.vim'), '\n')

	for l:ps in l:pluginScripts
	    execute 'source' s:fnameescape(l:ps)
	endfor
    endif
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
