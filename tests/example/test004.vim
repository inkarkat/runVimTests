" Test example demonstrating TAP unit test. 

" Note: This is the simple hard-coded version. 
call vimtap#SetOutputFile('test004.tap')
" To avoid hard-coding:
"   call vimtap#SetOutputFile(fnameescape(expand('<sfile>:r') . '.tap'))
" Or just use the friendly helper function: 
"   call vimtest#StartTap()

" Announce how many test assertions will be run. 
call vimtap#Plan(3)

" Assert that the unit-under-test works as expected. 
call vimtap#Ok(1, 'all right')
call vimtap#Is(1, 2, '1 == 2')	" Really?!
call vimtap#Diag('That was nonsense.')
call vimtap#Like('foobar 2000', 'fo\+.* \d\+', 'matches')

" Write the TAP results. 
call vimtap#FlushOutput()
" Note: You don't need to flush explicitly if you use the vimtest#... helpers. 

" Exit Vim so that the test result is evaluated. 
quit!
" Again, there's a helper function that has some nifty extras: 
"   call vimtest#Quit()

