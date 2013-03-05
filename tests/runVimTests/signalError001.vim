" Test error signal to test driver.

echomsg 'Still okay so far'
call vimtest#Error('')
echomsg 'That was an error without reason'
call vimtest#Error('This test does not test ABC.')
echomsg "So many errors, I'm done"
call vimtest#Quit()
