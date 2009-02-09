" Test with a testfile containing spaces. 

enew
normal! iSuccessful execution, even with spaces.
echomsg 'This is ' . expand('<sfile>:t')
call vimtest#SaveOut()
call vimtest#Quit()

