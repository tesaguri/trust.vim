let s:save_cpo = &cpo
set cpo&vim

let s:Filepath = vital#trust#import('System.Filepath')

" Common utilities:

if exists('+shellslash')
  let s:sep = '\'
else
  let s:sep = '/'
endif
" Use the path separator in the tree node name to represent metadata.
let s:trust_key = s:sep.'trust'

" A tree representing the file system and storing trust statuses of workspaces.
let s:tree = {}

function! s:PathComponents(path) abort
  return s:Filepath.split(resolve(s:Filepath.abspath(a:path)))
endfunction

" Get the tree node for a path.
function! s:GetNode(path) abort
  let l:node = s:tree
  for l:comp in s:PathComponents(a:path)
    if !has_key(l:node, l:comp)
      return
    endif
    let l:node = l:node[l:comp]
  endfor

  return l:node
endfunction

" Gets the tree node for a path, creating a new node if one does not exist.
function! s:Dig(path, node) abort
  let l:node = a:node
  for l:comp in s:PathComponents(a:path)
    if has_key(l:node, l:comp)
      let l:node = l:node[l:comp]
    else
      let l:next = {}
      let l:node[l:comp] = l:next
      let l:node = l:next
    endif
  endfor

  return l:node
endfunction

" Trust management:

function! trust#path#allow(path) abort
  return trust#path#set(a:path, v:true)
endfunction

function! trust#path#deny(path) abort
  return trust#path#set(a:path, v:false)
endfunction

function! trust#path#set(path, status) abort
  if a:status is# v:null
    return trust#path#remove(a:path)
  else
    let l:node = s:Dig(a:path, s:tree)
    let l:original = get(l:node, s:trust_key, v:null)
    let l:node[s:trust_key] = a:status
    return l:original
  endif
endfunction

function! trust#path#remove(path) abort
  let l:node = s:GetNode(a:path)
  if type(l:node) is# v:t_dict
    let l:original = get(l:node, s:trust_key, v:null)
    call remove(l:node, s:trust_key)
    return l:original
  endif
endfunction

function! trust#path#clear() abort
  let s:tree = {}
endfunction

" Persistent storage management:

function! s:FilePaths(...) abort
  if a:0 is# 0 || a:1 is# v:null
    let l:base_path = stdpath('data')
  else
    let l:base_path = a:1
  endif

  if type(l:base_path) is# v:t_string
    return [
      \s:Filepath.join(l:base_path, 'allow.txt'),
      \s:Filepath.join(l:base_path, 'deny.txt'),
      \]
  elseif type(l:base_path) is# v:t_dict
    return [
          \has_key(l:base_path, 'allow')
            \ ? l:base_path.allow
            \ : s:Filepath.join(stdpath('data'), 'allow.txt'),
          \has_key(l:base_path, 'deny')
            \ ? l:base_path.deny
            \ : s:Filepath.join(stdpath('data'), 'deny.txt'),
          \]
  endif
endfunction

function! s:ReadfileIfReadable(filename) abort
  if filereadable(a:filename)
    return readfile(a:filename, 'b')
  else
    return []
  endif
endfunction

function! trust#path#load(...) abort
  if a:0 >=# 2
    throw 'Too many arguments for function: trust#load'
  endif

  let [l:allowfile, l:denyfile] = call('s:FilePaths', a:000)

  let l:new_tree = {}

  for l:path in s:ReadfileIfReadable(l:allowfile)
    if empty(l:path)
      continue
    endif
    let l:node = s:Dig(l:path, l:new_tree)
    let l:node[s:trust_key] = v:true
  endfor

  for l:path in s:ReadfileIfReadable(l:denyfile)
    if empty(l:path)
      continue
    endif
    let l:node = s:Dig(l:path, l:new_tree)
    let l:node[s:trust_key] = v:false
  endfor

  let s:tree = l:new_tree
endfunction

function! trust#path#save(...) abort
  if a:0 >=# 2
    throw 'Too many arguments for function: trust#save'
  endif

  let [l:allowfile, l:denyfile] = call('s:FilePaths', a:000)

  if a:0 is# 0
    call mkdir(s:Filepath.join(stdpath('data'), 'trust'))
  elseif type(a:1) is# v:t_string
    call mkdir(a:1, 'p')
  endif

  let save_ssl = &shellslash
  set noshellslash " Make the output stable regardless of `&shellslash`.
  let [l:allowlist, l:denylist] = trust#workspaces()
  let &shellslash = save_ssl

  call writefile(l:allowlist, l:allowfile, 'b')
  call writefile(l:denylist, l:denyfile, 'b')
endfunction

" Trust query:

function! trust#path#is_allowed(path) abort
  let l:node = s:tree
  let l:ret = get(l:node, s:trust_key, v:false)

  for l:comp in s:PathComponents(a:path)
    if has_key(l:node, l:comp)
      let l:node = node[l:comp]
      let l:status = get(l:node, s:trust_key)
      if l:status
        let l:ret = v:true
      elseif type(l:status) is# v:t_bool
        let l:ret = v:false
      endif
    else
      return l:ret
    endif
  endfor

  return l:ret
endfunction

function! trust#path#get(path) abort
  let l:node = s:GetNode(a:path)
  if type(l:node) is# v:t_dict
    return get(l:node, s:trust_key, v:null)
  else
    return v:null
  endif
endfunction

function! s:Walk(node, path, allowlist, denylist) abort
  if has_key(a:node, s:trust_key)
    let l:path = empty(a:path)
      \ ? s:Filepath.separator()
      \ : (len(a:path) is# 2 && exists('+shellslash')
        \ ? a:path.s:Filepath.separator()
        \ : a:path)
    if a:node[s:trust_key]
      call add(a:allowlist, l:path)
    else
      call add(a:denylist, l:path)
    endif
  endif

  for [l:name, l:child] in items(a:node)
    " If the name starts with the path separator, it is metadata.
    if l:name[0] != s:sep
      let l:child_path = empty(a:path) && exists('+shellslash')
        \ ? l:name
        \ : s:Filepath.join(a:path, l:name)
      call s:Walk(l:child, l:child_path, a:allowlist, a:denylist)
    endif
  endfor
endfunction

function! trust#path#workspaces() abort
  let l:allowlist = []
  let l:denylist = []
  call s:Walk(s:tree, '', l:allowlist, l:denylist)
  return [l:allowlist, l:denylist]
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
