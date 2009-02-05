" Test successful TAP output without a plan. 

call vimtest#StartTap()

call vimtap#Ok(1, 'all right')
call vimtap#Is(1, 1, '1 == 1')
call vimtap#Like('foobar 2000', 'fo\+.* \d\+', 'matches')
call vimtap#Ok(1, 'also right')

call vimtest#Quit()

