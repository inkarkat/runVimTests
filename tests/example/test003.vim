" Test example demonstrating out and msgout. 

" Load the test data. 
" Note: This is the hard-coded hacker's version. 
edit test003.in
" To avoid hard-coding:
"   execute 'edit' fnameescape(expand('<sfile>:r') . '.in')

" This is the command-under-test: 
normal! gg3guu

" Save the processed buffer contents. 
" Note: This is the hard-coded hacker's version. 
write test003.out
" To avoid hard-coding:
"   execute 'write' fnameescape(expand('<sfile>:p:r') . '.out')
" Or just use the friendly helper function: 
"   call vimtest#SaveOut()

" Exit VIM so that the test result is evaluated. 
quit!
" Again, there's a helper function that has some nifty extras: 
"   call vimtest#Quit()

