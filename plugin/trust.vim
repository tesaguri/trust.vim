if exists('g:loaded_trust')
  finish
endif
let g:loaded_trust = 1

if exists('*nvim_echo')
  let s:Echo = function('nvim_echo')
else
  function s:Echo(chunks, _history, _opts)
    for l:chunk in a:chunks
      if len(l:chunk) >= 2
        execute 'echohl '.l:chunk[1]
      else
        echohl None
      endif
      echomsg l:chunk[0]
    endfor
    echohl None
  endfunction
end

function s:TrustAllow(path, ...)
  let l:path = expand(a:path)
  call trust#allow(l:path)
  if a:0 > 0
    for l:path in a:000
      call trust#allow(expand(l:path))
    endfor
    call s:Echo([['Trusted '], [string(a:0 + 1), 'Number'], [' paths']], 1, {})
  endif
endfunction

command -nargs=+ -complete=dir TrustAllow call s:TrustAllow(<f-args>)

function s:TrustDeny(path, ...)
  call trust#deny(expand(a:path))
  if a:0 > 0
    for l:path in a:000
      call trust#deny(expand(l:path))
    endfor
    call s:Echo(
      \[['Distrusted '], [string(a:0 + 1), 'Number'], [' paths']], 1, {}
      \)
  endif
endfunction

command -nargs=+ -complete=dir TrustDeny call s:TrustDeny(<f-args>)

function s:TrustRemove(path, ...)
  call trust#remove(expand(a:path))
  for l:path in a:000
    call trust#remove(expand(l:path))
  endfor
endfunction

command -nargs=+ -complete=dir TrustRemove call s:TrustRemove(<f-args>)

function s:TrustLoad(...)
  call call('trust#load', map(a:000, {_, base_path -> expand(base_path)}))
endfunction

if exists('*stdpath')
  command -nargs=? -complete=dir TrustLoad call s:TrustLoad(<f-args>)
else
  command -nargs=1 -complete=dir TrustLoad call s:TrustLoad(<f-args>)
endif

function s:TrustSave(...)
  call call('trust#save', map(a:000, {_, base_path -> expand(base_path)}))
endfunction

if exists('*stdpath')
  command -nargs=? -complete=dir TrustSave call s:TrustSave(<f-args>)
else
  command -nargs=1 -complete=dir TrustSave call s:TrustSave(<f-args>)
endif

function s:ListWorkspaces(workspaces)
  for l:workspace in a:workspaces
    call s:Echo([[l:workspace, 'Directory']], 1, {})
  endfor
endfunction

command TrustListAllowed call s:ListWorkspaces(trust#workspaces()[0])

command TrustListDenied call s:ListWorkspaces(trust#workspaces()[1])

if exists('*luaeval') && !luaeval('not vim.lsp')
  function s:TrustAllowWorkspace()
    let l:workspace = trust#lsp#last_root_dir()
    if l:workspace == v:null
      call s:Echo([['No workspace found', 'ErrorMsg']], 1, {})
      return
    endif
    call s:Echo([['Workspace is '], [l:workspace, 'Directory']], 1, {})
    if confirm('Trust the workspace?', "&Yes\n&No", 2, 'Question') == 1
      call trust#allow(l:workspace)
      call s:Echo(
        \[['Trusted workspace: '], [l:workspace, 'Directory']], 1, {},
      \)
    endif
  endfunction

  command TrustAllowWorkspace call s:TrustAllowWorkspace()
endif
