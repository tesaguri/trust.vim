if !exists('g:trust#sources')
  let g:trust#sources = ['trust#path#is_allowed']
endif

function! trust#is_allowed(path) abort
  for l:Source in g:trust#sources
    if call(l:Source, [a:path])
      return v:true
    endif
  endfor
  return v:false
endfunction

" Re-export `trust#path#*` for backwards compatibility:

function! trust#allow(...) abort
  return call('trust#path#allow', a:000)
endfunction

function! trust#deny(...) abort
  return call('trust#path#deny', a:000)
endfunction

function! trust#set(...) abort
  return call('trust#path#set', a:000)
endfunction

function! trust#remove(...) abort
  return call('trust#path#remove', a:000)
endfunction

function! trust#clear(...) abort
  return call('trust#path#clear', a:000)
endfunction

function! trust#load(...) abort
  return call('trust#path#load', a:000)
endfunction

function! trust#save(...) abort
  return call('trust#path#save', a:000)
endfunction

function! trust#get(...) abort
  return call('trust#path#get', a:000)
endfunction

function! trust#workspaces(...) abort
  return call('trust#path#workspaces', a:000)
endfunction
