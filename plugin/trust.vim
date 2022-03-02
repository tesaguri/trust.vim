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

function s:Trust(path, ...)
  let l:path = expand(a:path)
  call trust#trust(l:path)
  if a:0 > 0
    for l:path in a:000
      call trust#trust(expand(l:path))
    endfor
    call s:Echo([['Trusted '], [string(a:0 + 1), 'Number'], [' paths']], 1, {})
  endif
endfunction

command -nargs=+ -complete=dir Trust call s:Trust(<f-args>)

function s:Untrust(path, ...)
  let l:path = expand(a:path)
  let l:nr = trust#untrust(l:path)
  if a:0 == 0
    if !l:nr
      echomsg 'Path is not trusted, nothing to do'
    endif
  else
    for l:path in a:000
      let l:nr = l:nr + trust#untrust(expand(l:path))
    endfor
    call s:Echo([['Untrusted '], [string(l:nr), 'Number'], [' paths']], 1, {})
  endif
endfunction

command -nargs=+ -complete=dir Untrust call s:Untrust(<f-args>)

function s:Distrust(path, ...)
  call trust#distrust(a:path)
  if a:0 > 0
    for l:path in a:000
      trust#distrust(l:path)
    endfor
    call s:Echo(
      \[['Distrusted '], [string(a:0 + 1), 'Number'], [' paths'], 1, {}
      \)
  endif
endfunction

command -nargs=+ -complete=dir Distrust call s:Distrust(<f-args>)

function s:Undistrust(path, ...)
  let l:nr = trust#undistrust(a:path) == v:false
  if a:0 == 0
    if !l:nr
      echomsg 'Path is not distrusted, nothing to do'
    endif
  else
    for l:path in a:000
      let l:nr = l:nr + trust#undistrust(a:path) == v:false
    endfor
    call s:Echo([['Undistrusted '], [string(l:nr)], [' paths']], 1, {})
  endif
endfunction

command -nargs=+ -complete=dir Undistrust call s:Undistrust(<f-args>)

command TrustLoad lua require("trust").load_state()

command TrustSave lua require("trust").save_state()

function s:TrustList()
  try
    let l:Echo = function('s:Echo')
  catch
    " NeoVim
    let l:Echo = v:null
  endtry
  call luaeval('(function() _A = _A or vim.api.nvim_echo local list = vim.list or function(a) return a or {} end for w, s in require("trust").workspaces() do _A(list({ list({ w, "Directory" }), list({ "\t" }), list({ s and "trusted" or "distrusted" }) }), 1, list()) end end)()', l:Echo)
endfunction

command TrustList call s:TrustList()

if !luaeval('not vim.lsp')
  function s:TrustWorkspace()
    let l:workspace = trust#lsp#last_root_dir()
    if l:workspace == v:null
      call s:Echo([['No workspace found', 'ErrorMsg']], 1, {})
      return
    endif
    call s:Echo([['Workspace is '], [l:workspace, 'Directory']], 1, {})
    if confirm('Trust the workspace?', "&Yes\n&No", 2, 'Question') == 1
      call trust#trust(l:workspace)
      call s:Echo(
        \[['Trusted workspace: '], [l:workspace, 'Directory']], 1, {},
      \)
    endif
  endfunction

  command TrustWorkspace call s:TrustWorkspace()
endif
