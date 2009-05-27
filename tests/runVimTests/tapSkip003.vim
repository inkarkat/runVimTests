" Test different skipping methods. 

call vimtest#StartTap()
if ! vimtap#Skip(2, 0, 'foo')
    call vimtap#Is(1, 1, '1 == 1') 
    call vimtap#Is(2, 1, '2 == 1') 
endif
if ! vimtap#Skip(1, 0, 'fOO')
    call vimtap#Ok(0, 'not right')
endif
call vimtap#Is(1, 0, '# SKIP foo') 
call vimtap#Plan(0)

call vimtest#Quit()

