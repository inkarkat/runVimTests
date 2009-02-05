" Test failed TAP output. 

call vimtest#StartTap()
call vimtap#Plan(3)

call vimtap#Ok(1, 'all right')
call vimtap#Is(1, 2, '1 == 2')
call vimtap#Like('F00bAr 2000', 'fo\+.* \d\+', 'matches')
call vimtap#Diag('Some diagnostic message.')

call vimtest#Quit()

