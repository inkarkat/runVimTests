" Test error combination buffer + message + TAP output. 

enew
normal! iThis is never seen.
"call vimtest#SaveOut()

let s:msgoutFilespec=&verbosefile
set verbosefile=
call delete(s:msgoutFilespec)

call vimtest#StartTap()
call vimtap#Plan(3)
call vimtap#Ok(1, 'all right')
call vimtap#Is(1, 2, '1 == 2')

call vimtest#Quit() 

