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
"	001	26-Jan-2009	file creation

" Avoid installing twice or when in unsupported VIM version. 
" if exists('g:loaded_runVimMsgFilter') || (v:version < 700)
    " finish
" endif
" let g:loaded_runVimMsgFilter = 1

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
    normal! gg
    let l:startLineNum = 1
    let l:failures = []
    let l:successes = []

    for l:msgAssertion in a:msgAssertions
	if ! search(l:msgAssertion.regexp, 'cW')
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
    endfor
    call s:SetEndLineNum(l:failures, line('$'))

    return [l:failures, l:successes]
endfunction

function! s:Run( msgokBufNr, msgoutBufNr, resultBufNr )
    execute 'buffer' a:msgokBufNr
    let l:msgAssertions = s:LoadMsgAssertions()

    execute 'buffer' a:msgoutBufNr
    let [l:failures, l:successes] = s:ApplyMsgAssertions(l:msgAssertions)
echomsg string(l:failures)
echomsg string(l:successes)
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

    execute 'edit' l:baseFilespec . '.msgok'
    let l:msgokBufNr = bufnr('')
    execute 'edit' l:baseFilespec . '.msgout'
    let l:msgoutBufNr = bufnr('')
    enew
    let l:resultBufNr = bufnr('')

    call s:Run(l:msgokBufNr, l:msgoutBufNr, l:resultBufNr)
endfunction

command! -bar RunVimMsgFilter call <SID>LoadAndRun()

" vim: set sts=4 sw=4 noexpandtab ff=unix fdm=syntax :
