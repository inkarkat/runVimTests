runtime plugin/SidTools.vim
if has('win32') || has('win64')
    source O:/tools/runVimMsgFilter.vim
else
    source $HOME/bin/runVimMsgFilter.vim
endif

