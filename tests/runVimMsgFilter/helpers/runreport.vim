function! RunReport( testFilespec )
    let l:testFilename = fnamemodify(a:testFilespec, ':r')
    execute 'edit' l:testFilename . '.txt'
    let s:msgokBufNr = bufnr('')
    edit msgout.txt
    let s:msgoutBufNr = bufnr('')
    execute 'edit' l:testFilename . '.out'
    let s:resultBufNr = bufnr('')

    call SidInvoke('runVimMsgFilter.vim', 'Run(' . join([s:msgokBufNr, s:msgoutBufNr, s:resultBufNr], ',') . ')')

    call vimtest#Quit()
endfunction
