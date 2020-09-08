" This is the system-specific setup script used by the runVimTests test suite.

" If the project's tests reside in a "tests/" subdirectory, automatically put
" its parent directory onto 'runtimepath'. For the common "one repository per
" plugin" setup, this will make the plugin-under-test's scripts automatically
" available (for :runtime plugin/name.vim, or autoloading).
let s:testsDirspec = finddir('tests', getcwd() . ';')
if ! empty(s:testsDirspec)
    let s:rootDirspec = simplify(s:testsDirspec . '/..')
    if stridx(',' . &runtimepath . ',', ',' . s:rootDirspec . ',') == -1
	let &runtimepath = s:rootDirspec . ',' . &runtimepath . ',' . s:rootDirspec . '/after'
    endif
    unlet! s:rootDirspec
endif
unlet! s:testsDirspec

" Prefer vimtest.vim from the repository.
let &runtimepath = expand('<sfile>:p:h:h') . ',' . &runtimepath

" Use (first found) VimTAP from a repository next to runVimTests (if available).
let s:VimTAPRepositoryDirspec = $VIMTAP_HOME
if ! isdirectory(s:VimTAPRepositoryDirspec)
    let s:VimTAPRepositoryDirspec = substitute(
    \   glob(expand('<sfile>:p:h:h:h') . '/VimTAP*'),
    \   "\n.*", '', ''
    \)
endif
if ! isdirectory(s:VimTAPRepositoryDirspec)
    let s:VimTAPRepositoryDirspec = substitute(
    \   glob(expand('<sfile>:p:h:h:h:h:h') . '/*/start/VimTAP*'),
    \   "\n.*", '', ''
    \)
endif
if isdirectory(s:VimTAPRepositoryDirspec)
    let &runtimepath = s:VimTAPRepositoryDirspec . ',' . &runtimepath
endif


" Flag for ../tests/runVimTests/runVimTestsSetup/testRunVimTestsSetup.vim
let g:runVimTestsSetupDone = 1
