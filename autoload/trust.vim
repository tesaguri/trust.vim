function trust#trust(path)
  return luaeval('require("trust").trust(_A)', a:path)
endfunction

function trust#untrust(path)
  return luaeval('require("trust").untrust(_A)', a:path)
endfunction

function trust#distrust(path)
  return luaeval('require("trust").distrust(_A)', a:path)
endfunction

function trust#undistrust(path)
  return luaeval('require("trust").undistrust(_A)', a:path)
endfunction

function trust#set(path, status)
  " Pass `1` and `0` instead of `v:true` and `v:false` because Vim's `luaeval`
  " would convert them to numbers.
  let l:status = a:status ? 1 : string(a:status) == 'v:null' ? v:null : 0
  " Pass a Dictionary instead of a List because List userdata's indexes may be
  " 0-orign or 1-origin depending on patch versions.
  return luaeval(
    \'require("trust").set(_A.p, _A.s == 1 or _A.s == nil and nil)',
    \{ 'p': a:path, 's': l:status }
  \)
endfunction

function trust#remove(path)
  return luaeval('require("trust").remove(_A)', a:path)
endfunction

function trust#clear()
  return luaeval('require("trust").clear()')
endfunction

function trust#load_state(base_path = v:null)
  return luaeval('require("trust").load_state(_A)', a:base_path)
endfunction

function trust#save_state(base_path = v:null)
  return luaeval('require("trust").save_state(_A)', a:base_path)
endfunction

function trust#is_trusted(path)
  return luaeval('require("trust").is_trusted(_A)', a:path)
endfunction

function trust#get(path)
  return luaeval('require("trust").get(_A)', a:path)
endfunction

function trust#workspaces()
  return luaeval('(function() local list = vim.list or function(a) return a end for w, s in require("trust").workspaces() do table.insert(_A, list({ w, s })) end return _A end)()', [])
endfunction
