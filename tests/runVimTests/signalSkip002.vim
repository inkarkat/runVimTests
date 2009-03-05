" Test skip(out) signal to test driver. 

echomsg 'This is the expected result.'
normal! iCan write what I want, does not matter here.
call vimtest#StartTap()
call vimtap#Plan(1)
call vimtap#Ok(1, 'all right')

call vimtest#SkipOut("Lets just forget about the saved buffer contents.")

call vimtest#SaveOut()
call vimtest#Quit()

