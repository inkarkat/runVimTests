" Test that CWD is set to the test file's directory. 

call vimtest#StartTap()
call vimtap#Plan(1)

call vimtap#Is(getcwd(), expand('<sfile>:p:h'), 'CWD is test file''s directory')

call vimtest#Quit()

