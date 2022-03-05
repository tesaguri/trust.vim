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
  call trust#deny(a:path)
  if a:0 > 0
    for l:path in a:000
      trust#deny(l:path)
    endfor
    call s:Echo(
      \[['Distrusted '], [string(a:0 + 1), 'Number'], [' paths'], 1, {}
      \)
  endif
endfunction

command -nargs=+ -complete=dir TrustDeny call s:TrustDeny(<f-args>)

function s:TrustRemove(path, ...)
  call trust#remove(expand(a:path))
  for l:path in a:000
    trust#remove(l:path)
  endfor
endfunction

command -nargs=+ -complete=dir TrustRemove call s:TrustRemove(<f-args>)

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
