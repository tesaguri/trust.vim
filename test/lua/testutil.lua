local M = {}

local cmd = vim.cmd or vim.command
local eval = vim.eval or vim.api.nvim_eval
local inspect = vim.inspect or tostring

-- Vim 8.1 doesn't have `vim.call` nor `vim.funcref`.
if eval("has('win32')") ~= 0 then
  M.root = "C:\\"
  function M.path(comps)
    return table.concat(comps, "\\")
  end
else
  M.root = "/"
  function M.path(comps)
    return table.concat(comps, "/")
  end
end

function M.assert_eq(lhs, rhs)
  if lhs ~= rhs then
    error(
      "assertion failed: `" .. inspect(lhs) .. " == " .. inspect(rhs) .. "`",
      2
    )
  end
end

function M.skip(message)
  -- Use `vim.command` in case `vim.call` is unavailable. The behavior of the
  -- exception is documented by Themis so it should be safe rely upon.
  cmd(string.format([[throw 'themis: report: SKIP:'.%q]], message))
end

if vim.dict then
  function M.dict(t)
    -- Vim 8.1 cannot convert functions. Ignore the error for now.
    local status, d = pcall(vim.dict, t)
    if status then
      return d
    else
      print(d)
      return vim.dict()
    end
  end
elseif vim.type_idx then
  function M.dict(t)
    t[vim.type_idx] = vim.types.dictionary
    return t
  end
end

return M
