" Common utilities:

if has('win32')
  let s:sep = '\'
  let s:use_drive_letter = 1
else
  let s:sep = '/'
  let s:use_drive_letter = 0
endif
let s:trust_key = s:sep.'trust'

" A tree representing the file system and storing trust statuses of workspaces.
let s:tree = {}

function! s:IsAbsolute(path) abort
  if s:use_drive_letter
    return a:path =~? '^[A-Z]:'
  else
    return a:path[0] is# s:sep
  endif
endfunction

function! s:PathComponents(path) abort
  if s:IsAbsolute(a:path)
    let l:path = a:path
  else
    let l:path = getcwd().s:sep.a:path
  endif

  let l:path = substitute(resolve(l:path), s:sep.s:sep.s:sep.'*', s:sep, 'g')

  " Remove trailing path separator.
  if l:path[-1:] is# s:sep
    let l:path = l:path[0:-2]
  endif

  if s:use_drive_letter && l:path =~# '^[a-z]'
    let l:path = toupper(l:path[0]).l:path[1:]
  endif

  return split(l:path, s:sep)
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

function! trust#allow(path) abort
  call trust#set(a:path, v:true)
endfunction

function! trust#deny(path) abort
  call trust#set(a:path, v:false)
endfunction

function! trust#set(path, status) abort
  if a:status is# v:null
    return trust#remove(a:path)
  else
    let l:node = s:Dig(a:path, s:tree)
    let l:original = get(l:node, s:trust_key, v:null)
    let l:node[s:trust_key] = a:status
    return l:original
  endif
endfunction

function! trust#remove(path) abort
  let l:node = s:GetNode(a:path)
  if type(l:node) is# v:t_dict
    let l:original = get(l:node, s:trust_key, v:null)
    call remove(l:node, s:trust_key)
    return l:original
  endif
endfunction

function! trust#clear() abort
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
    return [l:base_path.s:sep.'allow.txt', l:base_path.s:sep.'deny.txt']
  elseif type(l:base_path) is# v:t_dict
    return [
          \has_key(l:base_path, 'allow') ? l:base_path.allow : stdpath('data').s:sep.'allow.txt',
          \has_key(l:base_path, 'deny') ? l:base_path.deny : stdpath('data').s:sep.'deny.txt',
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

function! trust#load(...) abort
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

function! trust#save(...) abort
  if a:0 >=# 2
    throw 'Too many arguments for function: trust#save'
  endif


  let [l:allowfile, l:denyfile] = call('s:FilePaths', a:000)

  if a:0 is# 0
    call mkdir(stdpath('data').s:sep.'trust')
  elseif type(a:1) is# v:t_string
    call mkdir(a:1, 'p')
  endif

  let [l:allowlist, l:denylist] = trust#workspaces()
  call writefile(l:allowlist, l:allowfile, 'b')
  call writefile(l:denylist, l:denyfile, 'b')
endfunction

" Trust query:

function! trust#is_allowed(path) abort
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

function! trust#get(path) abort
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
      \ ? s:sep
      \ : (s:use_drive_letter && len(a:path) is# 2 ? a:path.s:sep : a:path)
    if a:node[s:trust_key]
      call add(a:allowlist, l:path)
    else
      call add(a:denylist, l:path)
    endif
  endif

  for [l:name, l:child] in items(a:node)
    if l:name[0] != s:sep
      let l:child_path = empty(a:path) && s:use_drive_letter
        \ ? l:name
        \ : a:path.s:sep.l:name
      call s:Walk(l:child, l:child_path, a:allowlist, a:denylist)
    endif
  endfor
endfunction

function! trust#workspaces() abort
  let l:allowlist = []
  let l:denylist = []
  call s:Walk(s:tree, '', l:allowlist, l:denylist)
  return [l:allowlist, l:denylist]
endfunction
