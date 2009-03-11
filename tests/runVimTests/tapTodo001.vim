" Test Todo of some TAP tests. 

call vimtest#StartTap()
call vimtap#Plan(7)
call vimtap#Ok(1, 'all right')
call vimtap#Todo(2)
call vimtap#Is(1, 2, '1 == 2') 
call vimtap#Is(2, 2, '2 == 2') 
call vimtap#Is(1, 1, '1 == 1')
call vimtap#Todo(1)
call vimtap#Ok(1, 'not yet implemented')
call vimtap#Diag('We will implement this one soon.')
call vimtap#Todo(1)
call vimtap#Ok(0, 'not right')
call vimtap#Like('foobar 2000', 'fo\+.* \d\+', 'matches')

call vimtest#Quit()

