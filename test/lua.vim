let s:Filepath = vital#trust#import('System.Filepath')

if exists(':lua') is# 2
  verbose lua <<EOF
  print(_VERSION)
  if jit then
    print(jit.version)
  end
  print()
EOF
endif

execute 'set runtimepath^='.expand('<sfile>:h')

for s:chunk in glob(s:Filepath.join(expand('<sfile>:h'), '*.lua'), 1, 1)
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
