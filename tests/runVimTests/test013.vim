" Test missing message output. 

let s:msgoutFilespec=&verbosefile
set verbosefile=
call delete(s:msgoutFilespec)
call vimtest#Quit()

