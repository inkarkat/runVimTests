" Test skipping of some TAP tests. 

call vimtest#StartTap()
call vimtap#Plan(6)
call vimtap#Ok(1, 'all right')
if ! vimtap#Skip(2, 0, 'need different arithmetics')
    call vimtap#Is(1, 2, '1 == 2') 
    call vimtap#Is(2, 1, '2 == 1') 
endif
call vimtap#Is(1, 1, '1 == 1')
if ! vimtap#Skip(1, 0, 'need a miracle')
    call vimtap#Ok(0, 'not right')
endif
call vimtap#Like('foobar 2000', 'fo\+.* \d\+', 'matches')

call vimtest#Quit()

