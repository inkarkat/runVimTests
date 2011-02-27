" Test request of input. 

call vimtest#RequestInput("11")
let s:input = input("Enter something: ")
echo "You've entered: " . s:input


call vimtest#RequestInput("42")

" This is necessary to avoid that the next :echo is indented to the end of the
" request message, which is probably a minor Vim bug. Thanks to Luc St-Louis for
" reporting this. 
echo ""

let s:input = input("Enter something: ")

" This would be improperly indented in prompt002.msgout if we didn't issue the
" :echo "". 
echo "You've entered: " . s:input

call vimtest#Quit()
