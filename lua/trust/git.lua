---@private
local git = {}

--- Returns `true` if `HEAD` of the Git work tree at `path` is signed and the
--- work tree is clean.
function git.is_allowed(path)
  return vim.call("trust#git#is_allowed", path)
end

--- Returns a |Vital.Async.Promise| that resolves to a value representing the
--- validity of the signature of `HEAD` of the Git work tree at `path`.
function git.verify_commit(path)
  return vim.call("trust#git#verify_commit", path)
end

--- Returns a |Vital.Async.Promise| that resolves to `true` if the Git work tree
--- at `path` is dirty.
function git.is_dirty(path, ...)
  return vim.call("trust#git#is_dirty", path, ...)
end

return git
