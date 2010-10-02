" Test example demonstrating the out method. 

" Load the test data. 
edit testdata.in

" For simplicity, Vim's "lowercase" (gu) is the command-under-test. 
" We test lowercasing one complete line here. 
normal! gggugu

" Save the processed buffer contents. 
" The test framework compares this with the provided test001.ok. 
write test001.out

" Exit Vim so that the test result is evaluated. 
quit!

