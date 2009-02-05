" Test loading of assertions file. 

call vimtest#StartTap()
edit shortmsgok001.txt

let s:msgAssertions = SidInvoke('runVimMsgFilter.vim', 'LoadMsgAssertions()')
call vimtap#Is(len(s:msgAssertions), 5, 'Number of assertions')
call vimtap#Is(s:msgAssertions[0].regexp, '^\Vhihi\m\n', 'Assertion 0')
call vimtap#Is(s:msgAssertions[2].regexp, '^.*fo.*\nfo\+\nba[rz]\n', 'Assertion 2')
call vimtap#Is(s:msgAssertions[3].regexp, '^\s*\d\n\Vno more\m\n', 'Assertion 3')

let s:startLines = map(copy(s:msgAssertions), 'v:val.startline')
call vimtap#Is(s:startLines, [2, 4, 7, 11, 14], 'Assertion startlines')
let s:endLines = map(copy(s:msgAssertions), 'v:val.endline')
call vimtap#Is(s:endLines, [2, 4, 9, 12, 14], 'Assertion endlines')

call vimtest#Quit()

