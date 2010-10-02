" Test example demonstrating the msgout method. 

" For simplicity, Vim's "lowercase" (gu) is the command-under-test. 
" We test that the "cannot make changes" error is given on a nomodifiable
" empty buffer. 
setlocal nomodifiable
echomsg 'Test: Expecting E21 here'
normal! gugu

setlocal modifiable
echomsg 'Test: Expecting no error here'
normal! gugu
echomsg 'Test: Done'

" The test framework compares the Vim messages (captured in test002.msgout) with
" the provided test002.msgok. 
"
" Note how test002.msgok uses regular expressions to make the test independent
" of actual filespecs and operating system-specific path separator characters,
" and to detect the Vim error message even when the error message text is
" localized in a non-English language. 

" Exit Vim so that the test result is evaluated. 
quit!

