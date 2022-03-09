---@private
local trust = {}

---@private
local validate
if vim.validate then
  validate = vim.validate
else
  ---@private
  function validate(opt)
    for name, spec in pairs(opt) do
      local arg = spec[1]
      local type_name = spec[2]
      local optional = spec[3]

      if type(arg) ~= type_name and not (optional and arg == nil) then
        error(name .. ": expected " .. type_name .. ", got " .. type(arg), 2)
      end
    end
  end
end

---@private
local allow = vim.funcref("trust#allow")
--- Marks a path as trusted.
---
--- Workspaces at the path or its descendants (up to a path explicitly marked as
--- distrusted, if any) will be trusted.
---
---@param path string The path to trust.
---@return boolean The original status value of the node before this function is
--- called.
function trust.allow(path)
  validate { path = { path, "string" } }
  return allow(path)
end

---@private
local deny = vim.funcref("trust#deny")
--- Marks a path as distrusted.
---
--- Workspaces at the path or its descendants (up to a path explicitly marked as
--- trusted, if any) will be untrusted.
---
---@param path string The path to distrust.
---@return boolean The original status value of the node before this function is
--- called.
function trust.deny(path)
  validate { path = { path, "string" } }
  return deny(path)
end

---@private
local set = vim.funcref("trust#set")
--- Sets the raw trust status of a path.
---
---@param path string The path to set trust status.
---@param status boolean|nil Trust status value. `true` to trust, `false` to
--- distrust, `nil` to unset.
---@return boolean The original status value of the node before this function is
--- called.
function trust.set(path, status)
  validate { path = { path, "string" }, status = { status, "boolean", true } }
  return set(path, status)
end

---@private
local remove = vim.funcref("trust#remove")
--- Removes the marker of (dis)trust of a path if it has been marked with
--- |trust#allow()| or |trust#deny()|.
---
---@param path string The path to unmark.
function trust.remove(path)
  validate { path = { path, "string" } }
  return remove(path)
end

-- XXX: When a function with no arguments and a top-level variable have a same
-- name, Doxygen takes the function to be a variable. Therefore giving the
-- funcref a different name.
---@private
local f = vim.funcref("trust#clear")
--- Clears the status of (dis)trust of all paths.
function trust.clear()
  f()
end

---@private
local function validate_base_path(base_path)
  if
    type(base_path) ~= "string"
    and type(base_path) ~= "table"
    and base_path ~= nil
  then
    error("base_path: expected string|table|nil, got " .. type(base_path), 2)
  end
end

---@private
local load = vim.funcref("trust#load")
--- Loads trust statuses from files.
---
--- Overwrites the on-memory trust statuses.
---
---@param base_path string|table|nil String of the path to a directory
--- containing the status files or a table with `allow` and `deny` keys, each of
--- whose value is a string of the path to a status file.
--- Defaults to `stdpath("data")."/trust"` (requires NeoVim).
function trust.load(base_path)
  validate_base_path(base_path)
  load(base_path)
end

---@private
local save = vim.funcref("trust#save")
--- Saves the on-memory trust statuses into files.
---
---@param base_path string|table|nil String of the path to a directory to save the
--- status files in or a table with `allow` and `deny` keys, each of whose value
--- is a string of the path to save the status file.
--- Defaults to `stdpath("data")."/trust"` (requires NeoVim).
function trust.save(base_path)
  validate_base_path(base_path)
  save(base_path)
end

---@private
local is_allowed = vim.funcref("trust#is_allowed")
--- Returns `true` if the path is trusted.
---
---@param path string Path to a workspace.
---@return boolean `true` if the path is trusted, `false` otherwise.
function trust.is_allowed(path)
  validate { path = { path, "string" } }
  return is_allowed(path)
end

---@private
local get = vim.funcref("trust#get")
--- Returns the raw trust status of a path.
---
--- Unlike |trust#is_allowed()|, this does not respect the trust status of
--- ancestor paths.
---
---@return boolean|nil `true` if the path is explicitly marked as trusted,
--- `false` if marked as distrusted, `nil` otherwise.
function trust.get(path)
  validate { path = { path, "string" } }
  return get(path)
end

---@private
local f = vim.funcref("trust#workspaces")
--- Returns the list of (dis)trusted workspaces as an array of arrays, whose
--- first element is a list of trusted workspaces and the second is a list of
--- distrusted workspaces.
---
--- If the trust status is modified between the iterator function calls, its
--- return value is unspecified.
---
---@return function An iterator over (dis)trusted paths and their trust status.
function trust.workspaces()
  return f()
end

return trust
