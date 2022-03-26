let s:save_cpo = &cpo
set cpo&vim

let s:Promise = vital#trust#import('Async.Promise')
let s:Job = vital#trust#import('System.Job')

function! s:DefGlobalGetter(name, default) abort
  function! s:{a:name}() abort closure
    if exists('g:trust#git#'.a:name)
      return g:trust#git#{a:name}
    else
      return a:default
    endif
  endfunction
endfunction

" Allow dirty repositories by default assuming that you only clone a repository
" (rather than, e.g. download a tarball) and changes in the worktree are solely
" yours.
call s:DefGlobalGetter('allow_dirty', 1)
" These settings only apply when `allow_dirty` is disabled:
call s:DefGlobalGetter('allow_untracked', 0)
call s:DefGlobalGetter('allow_dirty_submodule', 0)
call s:DefGlobalGetter('allow_ignored', 0)

if has('win32')
  let s:sep = '\'
else
  let s:sep = '/'
endif
function! s:IsDescendant(path) abort
  if a:path[:2] is# '..'.s:sep || a:path[:3] is# '"..'.s:sep
    return 0
  else
    return 1
  endif
endfunction

function! s:Boolean(value) abort
  return a:value ? v:true : v:false
endfunction

" Read a porcelain format v2 line of `git-status(1)` and returns truthy iff the
" line denotes that the current directory is dirty.
function! s:IsDirtyStatusLine(line) abort
  let l:type = a:line[0]
  if l:type is# '#'
    " Ignore headers.
    return 0
  elseif l:type is# '1'
    return s:IsDescendant(a:line[113:])
  elseif l:type is# '2'
    let l:i = stridx(a:line, ' ', 113)
    let [l:path, l:orig_path] = split(a:line[(l:i + 1):], "\t")
    return s:IsDescendant(l:path) || s:IsDescendant(l:orig_path)
  elseif l:type is# 'u'
    return s:IsDescendant(a:line[161:])
  elseif l:type is# '?'
    return s:IsDescendant(a:line[2:])
  elseif l:type is# '!'
    return s:IsDescendant(a:line[2:])
  else
    " Conservatively treat an unknown type as dirty.
    return 1
  endif
endfunction

function! s:ParseValidity(line) abort
  let l:match = matchlist(a:line, '^\[GNUPG:\] \%(TRUST_\([^ ]*\)\|\%(\(E\)XP\|\(R\)EV\)KEYSIG\>\)')
  if !empty(l:match)
    if !empty(l:match[1])
      try
        return trust#gpg#validity(l:match[1])
      catch '^trust#gpg:INVALID_VALIDITY\>'
        echohl WarningMsg
        echomsg 'trust#git: Unknown validity status line: TRUST_'.l:match[1]
        echohl None
      endtry
    elseif !empty(l:match[2])
      return trust#gpg#validity('EXPIRED')
    elseif !empty(l:match[3])
      return trust#gpg#validity('REVOKED')
    else
      throw 'trust#git:UNREACHABLE: Reached unreachable code'
    endif
  endif
  return v:null
endfunction

function! trust#git#is_allowed(path) abort
  let l:promise = trust#git#verify_commit(a:path)
    \.catch({-> trust#gpg#validity('ERR')})
    \.then({validity -> validity >=# trust#gpg#min_validity()
      \ ? 0
      \ : Promise.reject(1)
      \})
  " vint: next-line -ProhibitUsingUndeclaredVariable
  if !s:allow_dirty()
    let l:dirty = trust#git#is_dirty(a:path)
      \.then({status -> status ? s:Promise.reject(1) : 0})
    let l:promise = Promise.all([l:promise, l:dirty])
  endif
  let [_, l:err] = s:Promise.wait(l:promise)
  return l:err is# v:null
endfunction

function! trust#git#verify_commit(path) abort
  let l:cmd = ['git', '-C', a:path, 'verify-commit', '--raw', 'HEAD']

  let l:validity = v:null

  let l:buf = ''
  function! s:on_stderr(data) abort closure
    if l:validity isnot# v:null
      return
    endif
    let a:data[0] = a:data[0].l:buf
    let l:buf = remove(a:data, -1)
    for l:line in a:data
      let l:validity = s:ParseValidity(l:line)
      if l:validity isnot# v:null
        return
      endif
    endfor
  endfunction

  let l:promise = s:Promise.new({Resolve, Reject -> s:Job.start(l:cmd, {
    \'on_stderr': funcref('s:on_stderr'),
    \'on_exit': {status -> l:validity is# v:null
      \ ? Reject(status ? status : -1)
      \ : Resolve(l:validity)},
    \})})
  return l:promise
endfunction

function! s:is_dirty(path, dict) abort
  " vint: next-line -ProhibitUsingUndeclaredVariable
  let l:allow_untracked = get(a:dict, 'allow_untracked', s:allow_untracked())
  " vint: next-line -ProhibitUsingUndeclaredVariable
  let l:allow_dirty_submodule =
    \get(a:dict, 'allow_dirty_submodule', s:allow_dirty_submodule())
  " vint: next-line -ProhibitUsingUndeclaredVariable
  let l:allow_ignored = get(a:dict, 'allow_ignored', s:allow_ignored())

  let l:cmd = ['git',
    \'-C', a:path,
    \'-c', 'status.relativePaths=true',
    \'status',
    \'--porcelain=v2',
    \]

  call add(l:cmd, a:allow_untracked
    \? '--untracked-files=no'
    \: '--untracked-files=normal')
  call add(l:cmd, a:allow_dirty_submodule
    \? '--ignore-submodules=all'
    \: '--ignore-submodules=none')
  call add(l:cmd,  a:allow_ignored
    \? '--ignored=no'
    \: '--ignored=matching')

  let l:is_dirty = 0

  let l:buf = ''
  function! s:on_stdout(data) abort closure
    if !l:is_dirty
      let a:data[0] = a:data[0].l:buf
      let l:buf = remove(a:data, -1)
      for l:line in a:data
        if s:IsDirtyStatusLine(l:line)
          let l:is_dirty = 1
          return
        endif
      endfor
    endif
  endfunction

  let l:promise = s:Promise.new({Resolve, Reject -> s:Job.start(l:cmd, {
    \'on_stdout': funcref('s:on_stdout'),
    \'on_exit': {status -> status
      \ ? Reject(a:status)
      \ : Resolve(s:Boolean(
        \l:is_dirty || (!empty(l:buf) && s:IsDirtyStatusLine(l:buf))))
      \},
    \})})

  return l:promise
endfunction

function! trust#git#is_dirty(path, ...) abort
  if a:0
    return call('s:is_dirty', [a:path] + a:000)
  else
    return call('s:is_dirty', [a:path, {}])
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
