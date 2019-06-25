
if has('python3')
    command! -nargs=1 Python py3 <args> 
    command! -nargs=1 Pyeval py3eval <args>
else                                       
    command! -nargs=1 Python py <args>
    command! -nargs=1 Pyeval pyeval <args>
endif

function! HyEval(str)
  py3 hy.eval(hy.read_str("(print " + vim.eval('a:str') + ")"))
endfunction

command! -nargs=1 Hy :call HyEval(<f-args>)

let g:jedhy_completion_path = fnamemodify(expand('<sfile>'), ':p:h')
let g:jedhy_wrapper_path = g:jedhy_completion_path . '/serv.hy'

Python import sys
exe 'Python sys.path.insert(0, "' . escape(g:jedhy_completion_path, '\"') . '")'
Python import hy
Python import vim
Python from importlib import reload
Python import jedhyclient
Python jedhyclient=reload(jedhyclient)

let g:jedhy_port = 50002

function! HyCompletionInit()
  Python jedhyclient.init_server(vim.eval('g:jedhy_wrapper_path'), vim.eval('g:jedhy_port'))
endfunction

function! HyCompletionInitMaybe()
  Python jedhyclient.init_server_maybe(vim.eval('g:jedhy_wrapper_path'), vim.eval('g:jedhy_port'))
endfunction


function! HyKillCompletion()
  Python jedhyclient.kill_server()
endfunction

function! HyLoadFile(file)
  let a:path=fnamemodify(a:file, ':p:h')
  "echo a:file
  "echo a:path
  Python jedhyclient.change_dir(vim.eval("a:path"))
  Python jedhyclient.load_file(vim.eval("a:file"))
endfunction

function! HyCompletion(findstart, prefix)
	  if a:findstart
	    " locate the start of the word
	    let line = getline('.')
	    let start = col('.') - 1
	    while start > 0 && (line[start - 1] =~# '\a' || line[start - 1] ==# '.')
       echo line[start-1]
	      let start -= 1
	    endwhile
	    return start
	  else
	    let result = []
     Python jedhyclient.complete(vim.eval("a:prefix"))
     return result
   endif
endfunction

command! HyLoadCurrentFile call HyLoadFile(expand('%:p'))
command! HyCompletionInit call HyCompletionInit()

function! HyCompletionAutocmd ()
  call HyCompletionInitMaybe()
  call setlocal omnifunc=HyCompletion()
  HyLoadCurrentFile
endfunction

augroup hycompletion
  autocmd FileType hy call HyCompletionAutocmd()
augroup END
