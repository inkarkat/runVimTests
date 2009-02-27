" Test failed TAP output. 

call vimtest#StartTap()
call vimtap#Plan(1)

call vimtap#Ok(0, 'not all right')

call vimtest#Quit()

