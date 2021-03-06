let s:save_cpo = &cpo
set cpo&vim

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
  return a:path[:2] isnot# '..'.s:sep && a:path[:3] isnot# '"..'.s:sep
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
  let l:match = matchlist(
    \a:line,
    \'^\[GNUPG:\] \%(TRUST_\([^ ]*\)\|\(EXP\|REV\)KEYSIG\|\(ERRSIG\)\>\)'
    \)
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
      if l:match[2] is# 'EXP'
        return trust#gpg#validity('EXPIRED')
      elseif l:match[2] is# 'REV'
        return trust#gpg#validity('REVOKED')
      endif
    elseif !empty(l:match[3])
      return trust#gpg#validity('ERR')
    endif
    throw 'trust#git:UNREACHABLE: Reached unreachable code'
  endif
  return v:null
endfunction

function! trust#git#is_allowed(path) abort
  if !exists('s:Promise')
    let s:Promise = vital#trust#import('Async.Promise')
  endif
  let l:promise = s:Promise.new(
    \{Resolve -> trust#git#async_is_allowed(a:path, {value -> Resolve(value)})}
    \)
  return s:Promise.wait(l:promise)[0]
endfunction

function! trust#git#async_is_allowed(path, callback) abort
  let l:resolved = 0
  let l:rejected = 0

  function! s:resolve() abort closure
    if l:resolved
      call a:callback(1)
    else
      let l:resolved += 1
    endif
  endfunction

  function! s:reject() abort closure
    if !l:rejected
      call a:callback(0)
      let l:rejected = 1
    endif
  endfunction

  function! s:reject_verify_commit() closure
    if exists('l:dirty')
      call l:dirty.stop()
    endif
    call s:reject()
  endfunction
  let l:verify_commit = s:verify_commit(
    \a:path,
    \{validity -> validity >=# trust#gpg#min_validity()
      \ ? s:resolve()
      \ : s:reject_verify_commit()
      \},
    \{-> trust#gpg#validity('ERR') >=# trust#gpg#min_validity()
      \ ? s:resolve()
      \ : s:reject_verify_commit()
      \},
    \)
  " vint: next-line -ProhibitUsingUndeclaredVariable
  if s:allow_dirty()
    call s:resolve()
  else
    function! s:reject_is_dirty() closure
      call l:verify_commit.stop()
      call s:reject()
    endfunction
    let l:dirty = s:is_dirty(
      \a:path,
      \{value -> value ? s:reject_is_dirty() : s:resolve()},
      \{-> s:reject_is_dirty()},
      \)
  endif
endfunction

function! s:verify_commit(path, on_resolve, on_reject) abort
  if executable('git') isnot# 1
    throw 'trust#git:GIT_NOT_FOUND: command not found: git'
  endif
  if executable('gpg') isnot# 1
    throw 'trust#git:GPG_NOT_FOUND: command not found: gpg'
  endif

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

  return s:Job.start(l:cmd, {
    \'on_stderr': funcref('s:on_stderr'),
    \'on_exit': {status -> l:validity is# v:null
      \ ? a:on_reject(status ? status : -1)
      \ : a:on_resolve(l:validity)
      \},
    \})
endfunction

function! trust#git#verify_commit(path, on_resolve, on_reject) abort
  " Drop the return value as it is not meant to be in the public API.
  call s:verify_commit(a:path, a:on_resolve, a:on_reject)
endfunction

function! s:is_dirty(path, on_resolve, on_reject, dict) abort
  if executable('git') isnot# 1
    throw 'trust#git:GIT_NOT_FOUND: command not found: git'
  endif

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

  call add(l:cmd, l:allow_untracked
    \ ? '--untracked-files=no'
    \ : '--untracked-files=normal')
  call add(l:cmd, l:allow_dirty_submodule
    \ ? '--ignore-submodules=all'
    \ : '--ignore-submodules=none')
  call add(l:cmd, l:allow_ignored
    \ ? '--ignored=no'
    \ : '--ignored=matching')

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

  return s:Job.start(l:cmd, {
    \'on_stdout': funcref('s:on_stdout'),
    \'on_exit': {status -> status
      \ ? a:on_reject(status)
      \ : a:on_resolve(
        \s:Boolean(
          \l:is_dirty || (!empty(l:buf) && s:IsDirtyStatusLine(l:buf))
          \),
        \)
      \},
    \})
endfunction

function! trust#git#is_dirty(path, on_resolve, on_reject, ...) abort
  if a:0
    call call('s:is_dirty', [a:path, a:on_resolve, a:on_reject] + a:000)
  else
    call call('s:is_dirty', [a:path, a:on_resolve, a:on_reject, {}])
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
