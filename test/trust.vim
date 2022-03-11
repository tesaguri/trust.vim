let s:suite = themis#suite('trust')
let s:assert = themis#helper('assert')

if has('win32')
  let s:root = 'C:\'
  let s:sep = '\'
  let s:null = 'NUL'
else
  let s:root = '/'
  let s:sep = '/'
  let s:null = '/dev/null'
endif
function s:Path(comps)
  return join(a:comps, s:sep)
endfunction

function s:suite.after_each()
  call trust#clear()
endfunction

function s:suite.allow()
  call trust#allow(s:root.s:Path(['home', 'me']))
  call trust#deny(s:root.s:Path(['home', 'me', 'workspace', 'forks']))

  call s:assert.equals(trust#is_allowed(s:root), v:false)
  call s:assert.equals(trust#is_allowed(s:root.s:Path(['home'])), v:false)
  call s:assert.equals(trust#is_allowed(s:root.s:Path(['home', 'me'])), v:true)
  call s:assert.equals(trust#is_allowed(s:root.s:Path(['home', 'me', 'workspace'])), v:true)
  call s:assert.equals(trust#is_allowed(s:root.s:Path(['home', 'me', 'workspace', 'forks'])), v:false)
  call s:assert.equals(trust#is_allowed(s:root.s:Path(['home', 'me', 'workspace', 'forks', 'some_repository'])), v:false)

  call s:assert.equals(trust#workspaces(), [[resolve(s:root.s:Path(['home', 'me']))], [resolve(s:root.s:Path(['home', 'me', 'workspace', 'forks']))]])
endfunction

function s:suite.cwd()
  call trust#allow('')
  call s:assert.equals(trust#get(getcwd()), v:true)
endfunction

function s:suite.load()
  " `load` should overwrite current status:
  call trust#allow(s:root)
  call trust#load({'allow': s:null, 'deny': s:null})
  call s:assert.equals(trust#workspaces(), [[], []])

  call trust#allow(s:root)
  call trust#deny(s:root.s:Path(['foo']))

  let l:allow = tempname()
  let l:deny = tempname()

  call trust#save({'allow': l:allow, 'deny': l:deny})

  call s:assert.equals(readfile(l:allow, 'b'), [s:root])
  call s:assert.equals(readfile(l:deny, 'b'), [s:root.s:Path(['foo'])])

  call trust#load({'allow': l:deny, 'deny': l:allow})
  call delete(l:allow)
  call delete(l:deny)

  call s:assert.equals(trust#workspaces(), [[s:root.s:Path(['foo'])], [s:root]])
endfunction
