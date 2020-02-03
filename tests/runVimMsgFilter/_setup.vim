call vimtest#AddDependency('vim-ingo-library')
runtime plugin/SidTools.vim

let s:runVimMsgFilterFilespec = get(ingo#compat#globpath(substitute($PATH, ingo#os#PathSeparator(), ',', 'g'), 'runVimMsgFilter.vim', 0, 1), 0, '')
if empty(s:runVimMsgFilterFilespec)
    call vimtest#BailOut('runVimMsgFilter.vim not found in $PATH')
endif

execute 'source' ingo#compat#fnameescape(s:runVimMsgFilterFilespec)
