" Test failed saved buffer output. 

enew
normal! iNot what was expected.
call vimtest#SaveOut()
call vimtest#Quit()

