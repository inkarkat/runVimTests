" Test TAP output with errors. 

call vimtest#StartTap()
call vimtap#Plan(3)

call vimtap#Ok(1, 'all right')
call vimtap#Is(1, 1, '1 == 1')

call vimtest#Quit()

