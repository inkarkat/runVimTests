runtime plugin/SidTools.vim

let s:runVimMsgFilterFilespec = ingo#compat#globpath(substitute($PATH, ingo#os#PathSeparator(), ',', 'g'), 'runVimMsgFilter.vim')
if empty(s:runVimMsgFilterFilespec)
    call vimtest#BailOut('runVimMsgFilter.vim not found in $PATH')
endif

execute 'source' ingo#compat#fnameescape(s:runVimMsgFilterFilespec)
