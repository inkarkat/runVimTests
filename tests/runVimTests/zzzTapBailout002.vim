" Test additional TAP output after BailOut from TAP tests. 
" Tests that the test results after the bail out aren't counted.
" Tests that the test results after the bail out aren't printed.

call vimtest#StartTap()
call vimtap#Plan(6)
try
    call vimtap#Ok(1, 'all right')
    call vimtap#BailOut("It is so f...ed up!")
catch VimTAP:BailOut
endtry
call vimtap#Diag("I had to stop, this was bad!")
call vimtap#Like('foobar 2000', 'fo\+.* \d\+', 'matches')
call vimtap#Diag("But now I feel like continuing; WTF?!")
call vimtap#Is(1, 2, '1 == 2')

call vimtest#Quit()

