" Test skip signal to test driver. 

echomsg 'Can write what I want, does not matter here.'
normal! iCan write what I want, does not matter here.
call vimtest#StartTap()
call vimtap#Plan(1)
call vimtap#Ok(1, 'all right')

call vimtest#SaveOut()
call vimtest#SkipAndQuit("Let's just forget about this one.")

