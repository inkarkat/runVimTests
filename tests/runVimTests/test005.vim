" Test setting of test name and options. 

call vimtest#StartTap()
call vimtap#Plan(4)

call vimtap#Ok(exists('g:runVimTests'), 'test options are defined')
call vimtap#Like(g:runVimTests, '\%(^\|,\)\%(pure\|default\|user\)\%($\|,\)', 'VIM mode is contained in test options') 

call vimtap#Ok(exists('g:runVimTest'), 'test name is defined')
call vimtap#Is(g:runVimTest, expand('<sfile>:p'), 'test name is script filespec')

call vimtest#Quit()

