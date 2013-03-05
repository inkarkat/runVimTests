" Test inactive convenience function vimtest#SkipAndQuitIf().

normal! iCan write what I want, does not matter here.
call vimtest#StartTap()
call vimtap#Plan(1)
call vimtap#Ok(1, 'all right')

call vimtest#SaveOut()
call vimtest#SkipAndQuitIf(0, "Let us just forget about this one.")

normal! oThis should be in here!
call vimtest#SaveOut()
call vimtest#Quit()
