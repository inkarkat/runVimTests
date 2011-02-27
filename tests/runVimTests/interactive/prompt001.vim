" Test request of choice. 

call vimtest#StartTap()
call vimtap#Plan(2) 
call vimtest#RequestInput("NO")
call vimtap#Is(confirm("Do want?", "&No\n&Yes\n&Maybe"), 1, "selected NO")
call vimtest#RequestInput("YES")
call vimtap#Is(confirm("Do want?", "&No\n&Yes\n&Maybe"), 2, "selected YES")
call vimtest#Quit()
