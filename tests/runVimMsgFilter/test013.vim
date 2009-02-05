" Test applying of assertions. 
" Tests multiple msgok files against a particular msgout file and verifies that
" the ranges with failures correspond with the bad lines listed at the first
" line of the msgok file. 

function! s:Lines( results )
    let l:lines = []
    for l:result in a:results
	let l:startLine = get(l:result, 'startline', '')
	let l:endLine = get(l:result, 'endline', '')
	if ! empty(l:startLine) || ! empty(l:endLine)
	    call add(l:lines, l:startLine . (l:startLine == l:endLine ? '' : '-' . l:endLine))
	endif
    endfor
    return join(l:lines, ', ')
endfunction

function! s:Process( msgokFilename )
    execute 'edit!' a:msgokFilename

    " The first line of the msgok file contains the bad lines that we expect to fail. 
    let l:badLines = getline(1)
    call setline(1, '')

    let g:msgAssertions = SidInvoke('runVimMsgFilter.vim', 'LoadMsgAssertions()')

    " There is one msgout file for a number of msgok files. 
    let l:msgoutFilename = substitute(a:msgokFilename, 'ok\d\+', 'out', '')
    execute 'edit!' l:msgoutFilename

    let [l:failures, l:successes] = SidInvoke('runVimMsgFilter.vim', 'ApplyMsgAssertions(g:msgAssertions)')
    call vimtap#Is(s:Lines(l:failures), l:badLines, a:msgokFilename . ' bad lines')
    call vimtap#Is(len(l:failures) + len(l:successes), len(g:msgAssertions), a:msgokFilename . ' all assertions processed')
endfunction

call vimtest#StartTap()

" Process all msgok files one by one. 
let s:msgokFiles = split(glob('*msgok*.txt'), "\n")
call vimtap#Plan(len(s:msgokFiles) * 2)
for s:msgokFilename in s:msgokFiles
    call s:Process(s:msgokFilename)
endfor

call vimtest#Quit()

