" This is the system-specific setup script used by the runVimTests test suite.

" Prefer vimtest.vim from the repository.
let &runtimepath = expand('<sfile>:p:h:h') . ',' . &runtimepath

" Use VimTAP from a repository next to runVimTests (if available).
let s:VimTAPRepositoryDirspec = substitute(
    \ glob(expand('<sfile>:p:h:h:h') . '/VimTAP*'), "\n.*", '', '')
if isdirectory(s:VimTAPRepositoryDirspec)
    let &runtimepath = s:VimTAPRepositoryDirspec . ',' . &runtimepath
endif


" Flag for ../tests/runVimTests/runVimTestsSetup/testRunVimTestsSetup.vim
let g:runVimTestsSetupDone = 1
