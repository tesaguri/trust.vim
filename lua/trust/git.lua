---@private
local git = {}

---@private
local is_allowed = vim.funcref("trust#git#is_allowed")
function git.is_allowed(path)
  return is_allowed(path)
end

---@private
local verify_commit = vim.funcref("trust#git#verify_commit")
function git.verify_commit(path)
  return verify_commit(path)
end

---@private
local is_dirty = vim.funcref("trust#git#is_dirty")
function git.is_dirty(path, ...)
  return is_dirty(path, ...)
end

return git
