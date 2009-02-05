" Test TAP output with failures and too many tests. 

call vimtest#StartTap()
call vimtap#Plan(3)

call vimtap#Ok(0, 'not right')
call vimtap#Is(1, 2, '1 == 2')
call vimtap#Like('foobar 2000', 'fo\+.* \d\+', 'matches')
call vimtap#Ok(0, 'one too many, even wrong')
call vimtap#Ok(1, 'two too many')

call vimtest#Quit()

