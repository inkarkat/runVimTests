" Test bailout signal to test driver. 

normal! iOh this is so f...ed up!
call vimtest#SaveOut()
call vimtest#BailOut("It is so f...ed up!")
" Note: This needs to be checked manually, as the bail out aborts all result
" verfication.
normal! oThis shouldn't be in here!
call vimtest#SaveOut()
call vimtest#Quit()

