`runVimTests` implements a testing framework for Vim scripts and plugins.

    $ runVimTests [{options}] test001.vim|testsuite.txt|path/to/testdir/ [...]
    20 files with 33 tests; 2 skipped, 27 run: 16 OK, 11 failures, 6 errors.
    Tests with skips: test006.vim
    Skipped tests: test007.vim
        2 SKIP (tap): Need 'autochdir' option
    Failed tests: test002.vim test012.vim test014.vim test022.vim test032.vim
    Tests with errors: test003.vim test013.vim test023.vim test033.vim

The _VIM LICENSE_ applies to this script.
