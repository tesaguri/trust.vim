local git = {}

--- Returns `true` if `HEAD` of the Git work tree at `path` is signed with a
--- trusted key and the work tree is clean.
---
---@param path string A path to a directory under a Git work tree.
---@return boolean `true` if the commit is signed and the work tree is clean, or
--- `false` otherwise (including an error).
function git.is_allowed(path)
  return vim.call("trust#git#is_allowed", path)
end

--- Checks if `HEAD` of the Git work tree at `path` is signed with a truested
--- key and the worktree is clean, and asynchronously calls the callback to
--- notify the result.
---
---@param path string A path to a directory under a Git work tree.
---@param callback function A function to be called with `true` if the commit
--- is signed and the work tree is clean, or `false` otherwise (including an
--- error).
function git.async_is_allowed(path, callback)
  return vim.call("trust#git#async_is_allowed", path, callback)
end

--- Checks the validity of the signature of `HEAD` of the Git work tree at
--- `path` and asynchronously calls the callbacks to notify the result.
---
---@param path string A path to a directory under a Git work tree.
---@param on_resolve function A function to be called with the validity value of
--- the signature.
---@param on_reject function A function to be called with the status code
--- returned by `git` command when the check fails.
function git.verify_commit(path, on_resolve, on_reject)
  return vim.call("trust#git#verify_commit", path, on_resolve, on_reject)
end

--- Checks if the Git work tree at `path` is dirty and asynchronously calls
--- the callbacks to notify the result.
---
---@param path string A path to a directory under a Git work tree.
---@param on_resolve function A function to be called with `true` if the work
--- tree is dirty or `false` if dirty.
---@param on_reject function A function to be called with the status code
--- returned by `git` command when the check fails.
function git.is_dirty(path, on_resolve, on_reject, ...)
  return vim.call("trust#git#is_dirty", path, on_resolve, on_reject, ...)
end

return git
