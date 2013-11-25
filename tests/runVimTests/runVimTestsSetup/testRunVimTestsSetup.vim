" Test automatic sourcing of runVimTestsSetup.vim from the bin directory.

call vimtest#StartTap()
call vimtap#Plan(1)
call vimtap#Is(exists('g:runVimTestsSetupDone'), 1, 'Marker flag has been set')
call vimtest#Quit()
