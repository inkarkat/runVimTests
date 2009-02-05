" Test successful combination buffer + message output. 

enew
normal! iSuccessful execution.
call vimtest#SaveOut()

echomsg 'Successful execution.' 

call vimtest#Quit() 

