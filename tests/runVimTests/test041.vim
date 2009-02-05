" Test sourcing of local setup script. 

call vimtest#StartTap()
call vimtap#Plan(2)

call vimtap#Ok(exists('g:isLocalSetupScriptSourced'), 'sourcing of local setup script')
call vimtap#Is(g:isLocalSetupScriptSourced, 'runVimTests', 'sourcing of local setup script')
scriptnames

call vimtest#Quit()

