let s:Filepath = vital#trust#import('System.Filepath')

execute 'set runtimepath^='.expand('<sfile>:h')

if exists('*luaeval')
  verbose lua <<EOF
  print(_VERSION)
  if jit then
    print(jit.version)
  end
  print()
EOF
  " Lua interface of Vim 8.1 and prior does not load modules from runtimepath
  " automatically.
  if luaeval('not pcall(function() require("testutil") end)')
    " Not using `Vital.System.Filepath` because we are going to pass the path to
    " Lua, which does not respect `&shellslash`.
    if has('win32')
      function s:Path(...)
        return join(a:000, '\')
      endfunction
    else
      function s:Path(...)
        return join(a:000, '/')
      endfunction
    endif
    call luaeval(
      \'(function() package.path = _A .. ";" .. package.path end)()',
      \join(map(split(&runtimepath, ','), {_, p ->
        \s:Path(p, 'lua', '?.lua').';'.s:Path(p, 'lua', '?', 'init.lua')
        \},
      \), ';'),
      \)
  endif
endif

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
