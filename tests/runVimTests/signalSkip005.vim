" Test skip all individual signals to test driver.

echomsg 'Can write what I want, does not matter here.'
normal! iCan write what I want, does not matter here.
call vimtest#StartTap()
call vimtap#Plan(1)
call vimtap#Ok(0, 'Can test what I want, does not matter here.')

call vimtest#SkipOut("Let us just forget about the saved buffer contents.")
call vimtest#SkipMsgout("Let us just forget about the captured messages.")
call vimtest#SkipTap("Let us just forget about the TAP unit tests.")

call vimtest#SaveOut()
call vimtest#Quit()

