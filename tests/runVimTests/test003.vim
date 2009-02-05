" Test no buffer output was saved. 

enew
normal! iThis is never seen.
"call vimtest#SaveOut()
call vimtest#Quit()

