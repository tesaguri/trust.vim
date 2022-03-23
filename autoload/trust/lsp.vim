let s:save_cpo = &cpo
set cpo&vim

function! trust#lsp#hook_start_client() abort
  return luaeval('require("trust.lsp").hook_start_client()')
endfunction

function! s:set_safe_server(server, status) abort
  return luaeval(
    \'(function() require("trust.lsp").safe_servers[_A.sv] = _A.st == 1 end)()',
    \{ 'sv': a:server, 'st': !!a:status },
    \)
endfunction

function! trust#lsp#set_safe_server(server, ...) abort
  if a:0
    return call('s:set_safe_server', [a:server] + a:000)
  else
    return call('s:set_safe_server', [a:server, 1])
  endif
endfunction

function! trust#lsp#set_safe_servers(servers) abort
  return luaeval(
    \'(function() require("trust.lsp").safe_servers = _A end)()', a:servers,
    \)
endfunction

function! trust#lsp#is_safe_server(server) abort
  return luaeval('require("trust.lsp").safe_servers[_A]', a:server)
endfunction

function! trust#lsp#safe_servers() abort
  return luaeval('require("trust.lsp").safe_servers_array()')
endfunction

function! trust#lsp#last_root_dir() abort
  return luaeval('require("trust.lsp").last_root_dir')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
