local M = {}

local has = vim.funcref("has")
local inspect = vim.inspect or tostring

if has("win32") ~= 0 then
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
