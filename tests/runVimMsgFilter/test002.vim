" Test loading of assertions file that doesn't contain any assertions. 

call vimtest#StartTap()
enew
execute "normal! o\<CR>   \<CR> \<Tab>\<CR>"

let s:msgAssertions = SidInvoke('runVimMsgFilter.vim', 'LoadMsgAssertions()')
call vimtap#Is(len(s:msgAssertions), 0, 'Number of assertions')

call vimtest#Quit()

