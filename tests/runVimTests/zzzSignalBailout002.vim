" Test bailout signal to test driver stops execution of further test scripts. 

" This should never be executed, as the previous test has bailed out. 
call vimtest#Quit()

