" Test BailOut from TAP tests. 

call vimtest#StartTap()
call vimtap#Plan(6)
" Note: The current design of VimTAP requires that the VimTAP:BailOut exception
" is caught, so that the TAP output is still flushed and written to disk. This
" design is unfortunate; better avoid vimtap#BailOut() and use vimtest#BailOut()
" instead.
try
    call vimtap#Ok(1, 'all right')
    call vimtap#Is(1, 2, '1 == 2')
    call vimtap#Is(2, 2, '2 == 2')
    call vimtap#BailOut("It is so f...ed up!")
    call vimtap#Is(1, 1, '1 == 1')
    call vimtap#Ok(0, 'not right')
    call vimtap#Like('foobar 2000', 'fo\+.* \d\+', 'matches')
catch VimTAP:BailOut
endtry

call vimtest#Quit()

