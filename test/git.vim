let s:Filepath = vital#trust#import('System.Filepath')
let s:Promise = vital#trust#import('Async.Promise')

let s:testdir = expand('<sfile>:h')

let s:suite = themis#suite(expand('<sfile>:t:r'))
let s:assert = themis#helper('assert')

let s:tempnames = []

function s:SystemList(expr, ...)
  let l:output = call('systemlist', [a:expr] + a:000)
  if v:shell_error
    throw '`'.a:expr.'` exited with status '.v:shell_error.': '
      \.join(l:output, "\n")
  endif
  return l:output
endfunction

function s:UnletEnv(...)
  try
    let l:args = copy(a:000)
    execute 'unlet '.join(map(args, {_, name -> '$'.name}))
  catch /^Vim\%((\a\+)\)\=:E488/
    " Workaround for older Vim:
    for l:name in a:000
      execute 'let $'.l:name.' = ""'
    endfor
  endtry
endfunction

function s:suite.before()
  let $GNUPGHOME  = tempname()
  if !mkdir($GNUPGHOME , 'p', 0700)
    throw '`mkdir` failed'
  endif
  call add(s:tempnames, $GNUPGHOME)

  call writefile(
    \['trust-model direct'],
    \s:Filepath.join($GNUPGHOME, 'gpg.conf'),
    \)

  call s:SystemList('gpg --batch --generate-key', [
    \'%no-protection',
    \'%transient-key',
    \'Key-Type: RSA',
    \'Key-Length: 1024',
    \'Key-Usage: sign',
    \'Name-Comment: trust.vim test key',
    \'Expire-Date: 0',
    \])

  for l:line in s:SystemList('gpg --with-colons --list-keys --with-fingerprint')
    if l:line =~# '^fpr:'
      let s:fingerprint = split(l:line, ':')[9]
    endif
  endfor
  if !exists('s:fingerprint')
    throw 'Generated key not found'
  endif
endfunction

function s:suite.before_each()
  let $GIT_WORK_TREE = tempname()
  if !mkdir($GIT_WORK_TREE, 'p')
    throw '`mkdir` failed'
  endif
  call add(s:tempnames, $GIT_WORK_TREE)

  let $GIT_DIR = s:Filepath.join($GIT_WORK_TREE, '.git')

  let l:gitconfig = s:Filepath.join($GIT_WORK_TREE, 'gitconfig')
  let $GIT_CONFIG_GLOBAL = l:gitconfig
  let $GIT_CONFIG_SYSTEM = l:gitconfig

  call s:SystemList('git init')
  call s:SystemList('git config --local user.name test')
  call s:SystemList('git config --local user.email test@example.invalid')
  call s:SystemList('git config --local user.signingKey '.s:fingerprint)
endfunction

function s:suite.after_each()
  call s:SetOtrust(g:trust#gpg#ultimate)
  call s:UnletEnv(
    \'GIT_WORK_TREE',
    \'GIT_DIR',
    \'GIT_CONFIG_GLOBAL',
    \'GIT_CONFIG_GLOBAL',
    \)
endfunction

function s:suite.after()
  call s:UnletEnv('GNUPGHOME')
  for l:dir in s:tempnames
    call delete(l:dir, 'rf')
  endfor
endfunction

function s:SetOtrust(otrust)
  call s:SystemList(
    \'gpg --batch --import-ownertrust -',
    \[s:fingerprint.':'.a:otrust.':', ''],
    \)
endfunction

function s:suite.validity()
  call s:SystemList('git commit -S -m test --allow-empty')
  for l:otrust in range(g:trust#gpg#undefined, g:trust#gpg#ultimate)
    call s:SetOtrust(l:otrust)
    call s:assert.equals(
      \s:Promise.wait(trust#git#verify_commit($GIT_WORK_TREE)),
      \[l:otrust, v:null],
      \)
  endfor
endfunction

function s:suite.badsig()
  let l:path_sep = has('win32') ? ';' : ':'
  let l:save_path = $PATH
  " Override `gpg` with a script that generates a bad signature.
  let $PATH = s:Filepath.join(s:testdir, 'git', 'badsig-bin').l:path_sep.$PATH
  call s:SystemList('git commit -S -m test --allow-empty')
  let $PATH = l:save_path

  call s:assert.equals(
    \s:Promise.wait(trust#git#verify_commit($GIT_WORK_TREE)),
    \[v:null, 1],
    \)
endfunction

function s:suite.no_pubkey()
  call s:SystemList('git commit -S -m test --allow-empty')
  call s:SystemList('gpg --batch --yes --delete-secret-keys '.s:fingerprint)
  call s:SystemList('gpg --batch --delete-keys '.s:fingerprint)
  call s:assert.equals(
    \s:Promise.wait(trust#git#verify_commit($GIT_WORK_TREE)),
    \[-1, v:null],
    \)
endfunction

function s:suite.no_sig()
  call s:SystemList('git commit -m test --allow-empty')
  call s:assert.equals(
    \s:Promise.wait(trust#git#verify_commit($GIT_WORK_TREE)),
    \[v:null, 1],
    \)
endfunction

function s:suite.notgit()
  call s:UnletEnv('GIT_WORK_TREE', 'GIT_DIR')
  let l:path = tempname()
  call mkdir(l:path, 'p')
  call add(s:tempnames, l:path)
  call s:assert.equals(
    \s:Promise.wait(trust#git#verify_commit(l:path)),
    \[v:null, 128],
    \)
  call s:assert.equals(
    \s:Promise.wait(trust#git#is_dirty(l:path)),
    \[v:null, 128],
    \)
endfunction

function s:suite.dirtiness()
  call s:SystemList('git commit -m test --allow-empty')
  call s:assert.equals(
    \s:Promise.wait(trust#git#is_dirty($GIT_WORK_TREE)),
    \[v:false, v:null],
    \)
  call writefile([], s:Filepath.join($GIT_WORK_TREE, 'test'))
  call s:assert.equals(
    \s:Promise.wait(trust#git#is_dirty($GIT_WORK_TREE)),
    \[v:true, v:null],
    \)
endfunction
