function trust#lsp#hook_start_client()
  return luaeval('require("trust.lsp").hook_start_client()')
endfunction

function trust#lsp#set_safe_server(server, status = 1)
  return luaeval(
    \'(function() require("trust.lsp").safe_servers[_A.sv] = _A.st == 1 end)()',
    \{ 'sv': a:server, 'st': !!a:status },
    \)
endfunction

function trust#lsp#set_safe_servers(servers)
  return luaeval(
    \'(function() require("trust.lsp").safe_servers = _A end)()', a:servers,
    \)
endfunction

function trust#lsp#is_safe_server(server)
  return luaeval('require("trust.lsp").safe_servers[_A]', a:server)
endfunction

function trust#lsp#safe_servers()
  return luaeval('require("trust.lsp").safe_servers_array()')
endfunction

function trust#lsp#last_root_dir()
  return luaeval('require("trust.lsp").last_root_dir')
endfunction
