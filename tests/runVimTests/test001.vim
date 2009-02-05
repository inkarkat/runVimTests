" Test successful saved buffer output. 

enew
normal! iSuccessful execution.
call vimtest#SaveOut()
call vimtest#Quit()

