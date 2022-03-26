let s:suite = themis#suite(expand('<sfile>:t:r'))
let s:assert = themis#helper('assert')

let s:Filepath = vital#trust#import('System.Filepath')
if exists('+shellslash')
  let s:root = 'C:'.s:Filepath.separator()
  let s:null = 'NUL'
else
  let s:root = s:Filepath.separator()
  let s:null = s:Filepath.join(s:root, 'dev', 'null')
endif

function s:suite.after_each()
  call trust#clear()
endfunction

function s:suite.allow()
  call trust#allow(s:Filepath.join(s:root, 'home', 'me'))
  call trust#deny(s:Filepath.join(s:root, 'home', 'me', 'workspace', 'forks'))

  call s:assert.equals(trust#is_allowed(s:root), v:false)
  call s:assert.equals(trust#is_allowed(s:Filepath.join(s:root, 'home')), v:false)
  call s:assert.equals(trust#is_allowed(s:Filepath.join(s:root, 'home', 'me')), v:true)
  call s:assert.equals(trust#is_allowed(s:Filepath.join(s:root, 'home', 'me', 'workspace')), v:true)
  call s:assert.equals(trust#is_allowed(s:Filepath.join(s:root, 'home', 'me', 'workspace', 'forks')), v:false)
  call s:assert.equals(trust#is_allowed(s:Filepath.join(s:root, 'home', 'me', 'workspace', 'forks', 'some_repository')), v:false)

  call s:assert.equals(trust#workspaces(), [
    \[resolve(s:Filepath.join(s:root, 'home', 'me'))],
    \[resolve(s:Filepath.join(s:root, 'home', 'me', 'workspace', 'forks'))],
    \])
endfunction

function s:suite.cwd()
  call trust#allow('')
  call s:assert.equals(trust#get(getcwd()), v:true)
endfunction

function s:suite.load()
  let l:allow = tempname()
  let l:deny = tempname()

  let save_ssl = &shellslash
  if exists('+shellslash')
    set noshellslash
    let l:root = 'C:\'
    function s:CurrentRoot()
      return 'C:'.s:Filepath.separator()
    endfunction
    let l:iter = [0, 1]
  else
    let l:root = '/'
    function s:CurrentRoot()
      return '/'
    endfunction
    let l:iter = [0]
  endif

  for l:ssl in l:iter
    let &shellslash = l:ssl

    " `load` should overwrite current status:
    call trust#allow(s:CurrentRoot())
    call trust#load({'allow': s:null, 'deny': s:null})
    call s:assert.equals(trust#workspaces(), [[], []])

    call trust#allow(s:CurrentRoot())
    call trust#deny(s:Filepath.join(s:CurrentRoot(), 'foo'))

    let &shellslash = &l:ssl

    call trust#save({'allow': l:allow, 'deny': l:deny})

    " The file format should be stable regardless of `shellslash`.
    call s:assert.equals(readfile(l:allow, 'b'), [l:root])
    call s:assert.equals(readfile(l:deny, 'b'), [l:root.'foo'])
  endfor
  let &shellslash = save_ssl

  call trust#load({'allow': l:deny, 'deny': l:allow})

  call delete(l:allow)
  call delete(l:deny)

  call s:assert.equals(trust#workspaces(), [[s:Filepath.join(s:root, 'foo')], [s:root]])
endfunction
