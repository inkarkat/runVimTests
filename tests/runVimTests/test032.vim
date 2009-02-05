" Test failed combination buffer + message + TAP output. 

enew
normal! iNot what was expected. 
call vimtest#SaveOut()

echomsg 'Not what was expected.'  

call vimtest#StartTap()
call vimtap#Plan(3)
call vimtap#Ok(0, 'not right')
call vimtap#Is(1, 2, '1 == 2')
call vimtap#Like('F00bAr 2000', 'fo\+.* \d\+', 'matches') 
call vimtap#Diag('Some diagnostic message.')

call vimtest#Quit() 

