" Test example demonstrating out and msgout. 

" Load the test data. 
edit testdata.in

" For simplicity, Vim's "lowercase" (gu) is the command-under-test. 
" We test lowercasing all lines, and also verify that the "n lines changed"
" message is printed. 
" For demonstration purposes, let's make this fail by using the wrong visual
" mode ('v' vs. 'V'). 
normal! ggvGgu

" Save the processed buffer contents. 
" Note: This is the simple hard-coded version. 
write test003.out
" To avoid hard-coding:
"   execute 'write' fnameescape(expand('<sfile>:p:r') . '.out')
" Or just use the friendly helper function: 
"   call vimtest#SaveOut()

" Exit Vim so that the test result is evaluated. 
quit!
" Again, there's a helper function that has some nifty extras: 
"   call vimtest#Quit()

