local M = {}

local inspect = vim.inspect or tostring

local has_win32
if vim.eval then
  -- Vim 8.1 doesn't have `vim.funcref`.
  -- (it's documented but was not implemented then)
  has_win32 = vim.eval("has('win32')") ~= 0
else
  has_win32 = vim.funcref("has")("win32") ~= 0
end

if has_win32 then
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

if vim.dict then
  M.dict = vim.dict
elseif vim.type_idx then
  function M.dict(t)
    t[vim.type_idx] = vim.types.dictionary
    return t
  end
end

return M
