" Test successful TAP output. 

call vimtest#StartTap(expand('<sfile>'))
call vimtap#Plan(1)

call vimtap#Ok(1, 'all right')

call vimtest#Quit()

