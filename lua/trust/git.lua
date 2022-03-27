---@private
local git = {}

function git.is_allowed(path)
  return vim.call("trust#git#is_allowed", path)
end

function git.verify_commit(path)
  return vim.call("trust#git#verify_commit", path)
end

function git.is_dirty(path, ...)
  return vim.call("trust#git#is_dirty", path, ...)
end

return git
