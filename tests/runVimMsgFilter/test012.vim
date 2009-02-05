" Test applying of assertions. 
" Tests that patterns which include \n match the correct lines. 

call vimtest#StartTap()
edit shortmsgout.txt
call vimtap#Plan(10)

let g:msgAssertions = repeat([{'regexp': '^\n\%(.\+\n\)\+\n'}], 3)

let [s:failures, s:successes] = SidInvoke('runVimMsgFilter.vim', 'ApplyMsgAssertions(g:msgAssertions)')
call vimtap#Is(s:failures[0].startline, 16, 'Empty-line-delimited-block assertion: failure startline')
call vimtap#Is(s:failures[0].endline, 24, 'Empty-line-delimited-block assertion: failure endline')
"call vimtap#Is(s:failures, [], 'Empty-line-delimited-block assertion: no failures')
let s:startLines = map(copy(s:successes), 'v:val.startline')
call vimtap#Is(s:startLines, [2, 10], 'Empty-line-delimited-block assertion: success startlines')
let s:endLines = map(copy(s:successes), 'v:val.endline')
call vimtap#Is(s:endLines, [4, 15], 'Empty-line-delimited-block assertion: success endlines')

" Add an empty line at the beginning. 
normal! ggO
let [s:failures, s:successes] = SidInvoke('runVimMsgFilter.vim', 'ApplyMsgAssertions(g:msgAssertions)')
call vimtap#Is(s:failures, [], 'Empty-line-delimited-block assertion + begin line: no failures')
let s:startLines = map(copy(s:successes), 'v:val.startline')
call vimtap#Is(s:startLines, [1, 5, 16], 'Empty-line-delimited-block assertion + begin line: success startlines')
let s:endLines = map(copy(s:successes), 'v:val.endline')
call vimtap#Is(s:endLines, [3, 11, 24], 'Empty-line-delimited-block assertion + begin line: success endlines')

" Add an empty line at the end instead. 
1delete
normal! Go
let [s:failures, s:successes] = SidInvoke('runVimMsgFilter.vim', 'ApplyMsgAssertions(g:msgAssertions)')
call vimtap#Is(s:failures, [], 'Empty-line-delimited-block assertion + end line: no failures')
let s:startLines = map(copy(s:successes), 'v:val.startline')
call vimtap#Is(s:startLines, [2, 10, 23], 'Empty-line-delimited-block assertion + end line: success startlines')
let s:endLines = map(copy(s:successes), 'v:val.endline')
call vimtap#Is(s:endLines, [4, 15, 25], 'Empty-line-delimited-block assertion + end line: success endlines')

call vimtest#Quit()

