" Test skipping all TAP tests by announcing this in the plan. 

call vimtest#StartTap()
call vimtap#Plan(0)

call vimtest#Quit()

