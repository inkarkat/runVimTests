" Test sourcing of local setup script in subdirectory. 

call vimtest#StartTap()
call vimtap#Plan(2)

call vimtap#Ok(exists('g:isLocalSetupScriptSourced'), 'sourcing of local setup script in subdirectory')
call vimtap#Is(g:isLocalSetupScriptSourced, 'runVimTests/subdir', 'sourcing of local setup script in subdirectory')
scriptnames

call vimtest#Quit()

