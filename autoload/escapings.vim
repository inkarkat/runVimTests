" escapings.vim: Common escapings of filenames and wrappers around new VIM
" 7.2 fnameescape() and shellescape() functions. 
"
" TODO:
"   - Refine the VIM 7.0/7.1 emulation functions. 
"   - Test the functionality of the built-in functions; do they actually
"     deliver?
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"	001	05-Jan-2009	file creation

function! escapings#bufnameescape( filespec )
"*******************************************************************************
"* PURPOSE:
"   Escape a normal filespec syntax so that it can be used for the bufname(),
"   bufnr(), bufwinnr(), ... commands. 
"   Ensure that there are no double (back-/forward) slashes inside the path; the
"   anchored pattern doesn't match in those cases! 
"* ASSUMPTIONS / PRECONDITIONS:
"	? List of any external variable, control, or other element whose state affects this procedure.
"* EFFECTS / POSTCONDITIONS:
"	? List of the procedure's effect on each external variable, control, or other element.
"* INPUTS:
"	? Explanation of each argument that isn't obvious.
"* RETURN VALUES: 
"	? Explanation of the value returned.
"*******************************************************************************
    " Backslashes are converted to forward slashes, as the comparison is done with
    " these on all platforms, anyway (cp. :help file-pattern). 
    let l:escapedFilespec = tr(a:filespec, '\', '/')

    " Special file-pattern characters must be escaped: [ escapes to [[], not \[.
    let l:escapedFilespec = substitute(l:escapedFilespec, '[\[\]]', '[\0]', 'g')

    " The special filenames '#' and '%' need not be escaped when they are anchored
    " or occur within a longer filespec. 
    let l:escapedFilespec = escape(l:escapedFilespec, '*?,')

    " I didn't find any working escaping for {, so it is replaced with the ?
    " wildcard. 
    let l:escapedFilespec = substitute(l:escapedFilespec, '[{}]', '?', 'g')

    " The filespec must be anchored to ^ and $ to avoid matching filespec
    " fragments. 
    return '^' . l:escapedFilespec . '$'
endfunction

function! escapings#exescape( command )
"*******************************************************************************
"* PURPOSE:
"   Escape a shell command so that it can be used in ex commands. 
"* ASSUMPTIONS / PRECONDITIONS:
"	? List of any external variable, control, or other element whose state affects this procedure.
"* EFFECTS / POSTCONDITIONS:
"	? List of the procedure's effect on each external variable, control, or other element.
"* INPUTS:
"   a:filespec	    normal filespec
"* RETURN VALUES: 
"	? Explanation of the value returned.
"*******************************************************************************
    return escape(a:command, '\%#|' )
endfunction

function! escapings#fnameescape( filespec )
"*******************************************************************************
"* PURPOSE:
"   Escape a normal filespec syntax so that it can be used in ex commands. 
"* ASSUMPTIONS / PRECONDITIONS:
"	? List of any external variable, control, or other element whose state affects this procedure.
"* EFFECTS / POSTCONDITIONS:
"	? List of the procedure's effect on each external variable, control, or other element.
"* INPUTS:
"   a:filespec	    normal filespec
"* RETURN VALUES: 
"	? Explanation of the value returned.
"*******************************************************************************
if v:version >= 702
    return fnameescape(a:filespec)
else
    return escape( tr( a:filespec, '\', '/' ), ' \%#' )
endif
endfunction

function! escapings#shellescape( filespec, ... )
"*******************************************************************************
"* PURPOSE:
"   Escape a normal filespec syntax so that it can be used in shell commands. 
"   The filespec will be quoted properly. 
"   When the {special} argument is present and it's a non-zero Number, then
"   special items such as "!", "%", "#" and "<cword>" will be preceded by a
"   backslash.  This backslash will be removed again by the |:!| command.
"
"* ASSUMPTIONS / PRECONDITIONS:
"	? List of any external variable, control, or other element whose state affects this procedure.
"* EFFECTS / POSTCONDITIONS:
"	? List of the procedure's effect on each external variable, control, or other element.
"* INPUTS:
"   a:filespec	    normal filespec
"* RETURN VALUES: 
"	? Explanation of the value returned.
"*******************************************************************************
    let l:isSpecial = (a:0 > 0 ? a:1 : 0)
if v:version >= 702
    return shellescape(a:filespec, l:isSpecial)
else
    let l:escapedFilespec = (l:isSpecial ? escapings#fnameescape(a:filespec) : a:filespec)

    if has('dos16') || has('dos32') || has('win95') || has('win32') || has('win64')
	return '"' . l:escapedFilespec . '"'
    else
	return "'" . l:escapedFilespec . "'"
    endif
endif
endfunction

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
