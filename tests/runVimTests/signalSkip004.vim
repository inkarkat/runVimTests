" Test skip(tap) signal to test driver.

echomsg 'This is the expected result.'
normal! iThis is the expected result.
call vimtest#StartTap()
call vimtap#Plan(1)
call vimtap#Ok(0, 'Can test what I want, does not matter here.')

call vimtest#SkipTap("Let us just forget about the TAP unit tests.")

call vimtest#SaveOut()
call vimtest#Quit()

