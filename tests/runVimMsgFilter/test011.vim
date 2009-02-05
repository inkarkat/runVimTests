" Test applying of assertions. 
" Tests that the start and end lines of successes and failures are correct. 

call vimtest#StartTap()
edit shortmsgout.txt
call vimtap#Plan(15)

let g:msgAssertions = []
let [s:failures, s:successes] = SidInvoke('runVimMsgFilter.vim', 'ApplyMsgAssertions(g:msgAssertions)')
call vimtap#Is(s:failures, [], 'No failures when no assertions')
call vimtap#Is(s:successes, [], 'No successes when no assertions')

let g:msgAssertions = [{'regexp': '^\Vfoo\m\n\Vbar\m\n\Vbaz\m\n'}]
let [s:failures, s:successes] = SidInvoke('runVimMsgFilter.vim', 'ApplyMsgAssertions(g:msgAssertions)')
call vimtap#Is(s:failures, [], 'No failures for foo-bar-baz assertion')
call vimtap#Is(s:successes[0].startline, 12, 'Success startline for foo-bar-baz assertion')
call vimtap#Is(s:successes[0].endline, 14, 'Success endline for foo-bar-baz assertion')

call insert(g:msgAssertions, {'regexp': '^#\+\n'}, 0)
let [s:failures, s:successes] = SidInvoke('runVimMsgFilter.vim', 'ApplyMsgAssertions(g:msgAssertions)')
call vimtap#Is(s:failures[0].startline, 1, 'Failure startline for hashline assertion')
call vimtap#Is(s:failures[0].endline, 11, 'Failure endline for hashline assertion')
call vimtap#Is(s:successes[0].startline, 12, 'Success startline for foo-bar-baz assertion')
call vimtap#Is(s:successes[0].endline, 14, 'Success endline for foo-bar-baz assertion')

call add(g:msgAssertions, {'regexp': '^TODO:.*'})
let [s:failures, s:successes] = SidInvoke('runVimMsgFilter.vim', 'ApplyMsgAssertions(g:msgAssertions)')
call vimtap#Is(s:failures[0].startline, 1, 'Failure startline for hashline assertion')
call vimtap#Is(s:failures[0].endline, 11, 'Failure endline for hashline assertion')
call vimtap#Is(s:successes[0].startline, 12, 'Success startline for foo-bar-baz assertion')
call vimtap#Is(s:successes[0].endline, 14, 'Success endline for foo-bar-baz assertion')
call vimtap#Is(s:failures[1].startline, 15, 'Failure startline for todo assertion')
call vimtap#Is(s:failures[1].endline, 24, 'Failure endline for todo assertion')

call vimtest#Quit()

