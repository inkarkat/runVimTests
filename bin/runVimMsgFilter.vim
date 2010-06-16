" runVimMsgFilter.vim: Matching of *.msgok message assumptions against *.msgout
" file, writing results into *.msgresult. 
"
" DEPENDENCIES:
"   - Requires VIM 7.2 or higher.  
"     (Some bug in lower patch levels of VIM 7.1 causes a second message
"     condition to not match if a previous message condition matched the message
"     directly above; i.e. matches eat the following message, too.) 
"
" Copyright: (C) 2009 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"   1.00.004	02-Mar-2009	Reviewed for publication. 
"	003	10-Feb-2009	Using fnameescape(). 
"	002	28-Jan-2009	Now removing trailing empty line in result
"				buffer, so that the test results dump to stdout
"				isn't torn apart by an empty line. 
"				Shortened OK result summary to have less visual
"				clutter on the expected execution path. 
"	001	26-Jan-2009	file creation

" Avoid installing twice or when in unsupported VIM version. 
if exists('g:loaded_runVimMsgFilter') || (v:version < 702)
    finish
endif
let g:loaded_runVimMsgFilter = 1

function! s:ProcessLine( line )
    if a:line =~# '^\([^0-9a-zA-Z \t\\"]\)\1\@!.*\1$'
	let l:regExpDelimiter = strpart(a:line, 0, 1)
	" Extract the regexp out of the delimiters. 
	let l:regExp = strpart(a:line, 1, strlen(a:line) - 2)
	" And unescape any escaped regexp delimiters. 
	" Note: Inside this simplistic engine, escaping is not necessary, but
	" it's still good practice to make these regexps look as they would in
	" VIM. 
	let l:regExp = substitute(l:regExp, '\%(\%(^\|[^\\]\)\%(\\\\\)*\\\)\@<!\\' . l:regExpDelimiter, l:regExpDelimiter, 'g')
	return l:regExp . '\n'
    else
	" Literal string, encase in "very nomagic" block. 
	return '\V' . escape(a:line, '\') . '\m\n'
    endif
endfunction
function! s:LoadMsgAssertion( lineNum )
    let l:lineNum = a:lineNum
    while l:lineNum <= line('$') && getline(l:lineNum) =~# '^\s*$'
	let l:lineNum += 1
    endwhile
    if l:lineNum > line('$')
	return {}
    endif

    let l:startLineNum = l:lineNum
    let l:msgAssertion = '^'
    while getline(l:lineNum) !~#'^\s*$'
	let l:msgAssertion .= s:ProcessLine(getline(l:lineNum))
	let l:lineNum += 1
    endwhile
    return { 'startline': l:startLineNum, 'endline': l:lineNum - 1, 'regexp': l:msgAssertion }
endfunction
function! s:LoadMsgAssertions()
    let l:msgAssertions = []
    let l:lineNum = 1
    while 1
	let l:msgAssertion = s:LoadMsgAssertion(l:lineNum) 
	if empty(l:msgAssertion)
	    break
	else
	    let l:lineNum = l:msgAssertion.endline + 1
	    let l:msgAssertion.index = len(l:msgAssertions)
	    call add(l:msgAssertions, l:msgAssertion)
	endif
    endwhile
    return l:msgAssertions
endfunction

function! s:SetEndLineNum( failures, endLineNum )
    for l:failure in a:failures
	if ! has_key(l:failure, 'endline')
	    let l:failure.endline = a:endLineNum
	endif
    endfor
endfunction
function! s:ApplyMsgAssertions( msgAssertions )
    normal! G$
    let l:isFirstSearch = 1
    let l:startLineNum = 1
    let l:failures = []
    let l:successes = []

    for l:msgAssertion in a:msgAssertions
	" If the regexp begins with an empty line (\n), VIM doesn't match an
	" empty first line in the buffer, even when the 'c' flag is set. So
	" start from the very end and wrap around on the first search. 
	if ! search(l:msgAssertion.regexp, (l:isFirstSearch ? 'w' : 'cW'))
	    if l:isFirstSearch
		" The first search from the last character in the buffer didn't
		" succeed, so jump to start of buffer manually. 
		normal! gg
	    endif
	    let l:failure = { 'startline': l:startLineNum, 'assertion': l:msgAssertion }
	    call add(l:failures, l:failure)
	else
	    let l:startLineNum = line('.')
	    call s:SetEndLineNum(l:failures, l:startLineNum - 1)
	    let l:endLineNum = search(l:msgAssertion.regexp, 'ceW')
	    let l:success = { 'startline': l:startLineNum, 'endline': l:endLineNum, 'assertion': l:msgAssertion }
	    call add(l:successes, l:success)
	    let l:startLineNum = l:endLineNum + 1
	endif
	let l:isFirstSearch = 0
    endfor
    call s:SetEndLineNum(l:failures, line('$'))

    return [l:failures, l:successes]
endfunction

function! s:Print( text )
    set paste
    execute 'normal! i' . a:text . "\<CR>" 
    set nopaste
endfunction
function! s:LineRangeText( startLine, endLine )
    let l:isOneLine = (a:startLine == a:endLine)
    return (l:isOneLine ? 'line' : 'lines') . ' ' . a:startLine . (l:isOneLine ? '' : '-' . a:endLine)
endfunction
function! s:ReportFailures( failures )
    for l:failure in a:failures
	call s:Print(' --> Message assertion ' . (l:failure.assertion.index + 1) . ' from ' . s:LineRangeText(l:failure.assertion.startline, l:failure.assertion.endline) . ' did not match in output ' . s:LineRangeText(l:failure.startline, l:failure.endline))
	" Strip off leading ^. 
	let l:pattern = strpart(l:failure.assertion.regexp, 1)
	" Convert \n atom into both visible and actual newline, and indent pattern. 
	let l:pattern = '     ' . substitute(l:pattern, '\\n', '\\n\n     ', 'g')
	" Strip off "very nomagic" from literal patterns and end those with '$'
	" to indicate the literalness. 
	let l:pattern = substitute(l:pattern, '\\V\(.\{-}\)\\m\\n\n', '\1$\n', 'g')
	" Strip off last \n. 
	let l:pattern = substitute(l:pattern, '\n\s*$', '', '')
	call s:Print(l:pattern)
    endfor
endfunction
function! s:ReportResults( failures, successes )
    normal! ggdG
    if len(a:failures) == 0
	if len(a:successes) > 0
	    call s:Print('OK (msgout)')
	    "call s:Print('OK (msgout): ' . len(a:successes) . ' message assertion' . (len(a:successes) > 1 ? 's' : '') )
	else
	    call s:Print('ERROR (msgout): No message assertions were found. ' )
	endif
    else
	let l:msgAssertionNum = len(a:failures) + len(a:successes)
	if len(a:successes) == 0 && len(a:failures) > 1
	    call s:Print('FAIL (msgout): ALL ' . l:msgAssertionNum . ' message assertions were not satisfied by the output. ')
	elseif l:msgAssertionNum == 1
	    call s:Print('FAIL (msgout): The message assertion was not satisfied by the output: ')
	    call s:ReportFailures(a:failures)
	else
	    call s:Print('FAIL (msgout): ' . len(a:failures) . ' of ' . l:msgAssertionNum . ' message assertions ' . (len(a:failures) > 1 ? 'were' : 'was') . ' not satisfied by the output: ')
	    call s:ReportFailures(a:failures)
	endif
    endif

    " Delete trailing empty line. 
    $g/^$/d
endfunction

function! s:Run( msgokBufNr, msgoutBufNr, resultBufNr )
    execute 'buffer' a:msgokBufNr
    let l:msgAssertions = s:LoadMsgAssertions()

    execute 'buffer' a:msgoutBufNr
    let [l:failures, l:successes] = s:ApplyMsgAssertions(l:msgAssertions)
"****D echomsg '**** failures  ' . string(l:failures)
"****D echomsg '**** successes ' . string(l:successes)

    execute 'buffer' a:resultBufNr
    call s:ReportResults(l:failures, l:successes)
    write
endfunction

function! s:LoadAndRun()
    let l:baseFilespec = expand('%:p:r')
    if expand('%:e') !=# 'msgok'
	echohl ErrorMsg
	let v:errmsg = 'VimMsgFilter must be supplied a *.msgok file'
	echomsg v:errmsg
	echohl NONE
	return
    endif

    execute 'edit' fnameescape(l:baseFilespec . '.msgok')
    let l:msgokBufNr = bufnr('')
    execute 'edit' fnameescape(l:baseFilespec . '.msgout')
    let l:msgoutBufNr = bufnr('')
    execute 'edit' fnameescape(l:baseFilespec . '.msgresult')
    let l:resultBufNr = bufnr('')

    call s:Run(l:msgokBufNr, l:msgoutBufNr, l:resultBufNr)
endfunction

command! -bar RunVimMsgFilter call <SID>LoadAndRun()

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
