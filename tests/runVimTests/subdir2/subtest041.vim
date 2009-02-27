" Test no sourcing of nonexisting local setup script in subdirectory. 

call vimtest#StartTap()
call vimtap#Plan(1)

call vimtap#Ok(! exists('g:isLocalSetupScriptSourced'), 'no sourcing of nonexisting local setup script in subdirectory')
scriptnames

call vimtest#Quit()

