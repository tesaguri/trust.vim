if has('win32')
  let s:sep = '\'
else
  let s:sep = '/'
endif
function s:Path(comps)
  return join(a:comps, s:sep)
endfunction

if exists('*luaeval')
  lua <<EOF
  print(_VERSION)
  if jit then
    print(jit.version)
  end
EOF
endif

execute 'set runtimepath^='.expand('<sfile>:h')

for s:chunk in glob(s:Path([expand('<sfile>:h'), '*.lua']), 0, 1)
  let s:suite = themis#suite(fnamemodify(s:chunk, ':t:r'))
  if exists('*luaeval')
    for [s:name, s:F] in items(luaeval('dofile("'.escape(s:chunk, '\').'")'))
      let s:suite[s:name] = s:F
    endfor
  else
    function s:suite['']()
      call themis#helper('assert').skip('`+lua` feature is not enabled')
    endfunction
  endif
endfor
