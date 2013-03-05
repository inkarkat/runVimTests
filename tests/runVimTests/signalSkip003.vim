" Test skip(msgout) signal to test driver.

echomsg 'Can write what I want, does not matter here.'
normal! iThis is the expected result.
call vimtest#StartTap()
call vimtap#Plan(1)
call vimtap#Ok(1, 'all right')

call vimtest#SkipMsgout("Let us just forget about the captured messages.")

call vimtest#SaveOut()
call vimtest#Quit()

