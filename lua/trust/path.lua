---@private
local path = {}

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
local function from_vim(value)
  if value == vim.NIL then
    return nil
  end
  return value
end

--- Marks a path as trusted.
---
--- Workspaces at the path or its descendants (up to a path explicitly marked as
--- distrusted, if any) will be trusted.
---
---@param path string The path to trust.
---@return boolean|nil The original status value of the node before this
--- function is called.
function path.allow(path)
  validate { path = { path, "string" } }
  return from_vim(vim.call("trust#path#allow", path))
end

--- Marks a path as distrusted.
---
--- Workspaces at the path or its descendants (up to a path explicitly marked as
--- trusted, if any) will be untrusted.
---
---@param path string The path to distrust.
---@return boolean|nil The original status value of the node before this
--- function is called.
function path.deny(path)
  validate { path = { path, "string" } }
  return from_vim(vim.call("trust#path#deny", path))
end

--- Sets the raw trust status of a path.
---
---@param path string The path to set trust status.
---@param status boolean|nil Trust status value. `true` to trust, `false` to
--- distrust, `nil` to unset.
---@return boolean|nil The original status value of the node before this
--- function is called.
function path.set(path, status)
  validate { path = { path, "string" }, status = { status, "boolean", true } }
  return from_vim(vim.call("trust#path#set", path, status))
end

--- Removes the marker of (dis)trust of a path if it has been marked with
--- |trust.allow()| or |trust.deny()|.
---
---@param path string The path to unmark.
---@return boolean|nil The original status value of the node before this
--- function is called.
function path.remove(path)
  validate { path = { path, "string" } }
  return from_vim(vim.call("trust#path#remove", path))
end

--- Clears the status of (dis)trust of all paths.
function path.clear()
  vim.call("trust#path#clear")
end

---@private
local function validate_base_path(base_path)
  if type(base_path) == "string" or base_path == nil then
    -- ok
  elseif type(base_path) ~= "table" then
    validate {
      ["base_path.allow"] = { base_path.allow, "string", true },
      ["base_path.deny"] = { base_path.deny, "string", true },
    }
  else
    error("base_path: expected string|table|nil, got " .. type(base_path), 2)
  end
end

--- Loads trust statuses from files.
---
--- Overwrites the on-memory trust statuses.
---
---@param base_path string|table|nil String of the path to a directory
--- containing the status files or a table with `allow` and `deny` keys, each of
--- whose value is a string of the path to a status file.
--- Defaults to `stdpath("data")."/trust"` (requires Neovim).
function path.load(base_path)
  validate_base_path(base_path)
  vim.call("trust#path#load", base_path)
end

--- Saves the on-memory trust statuses into files.
---
---@param base_path string|table|nil String of the path to a directory to save the
--- status files in or a table with `allow` and `deny` keys, each of whose value
--- is a string of the path to save the status file.
--- Defaults to `stdpath("data")."/trust"` (requires Neovim).
function path.save(base_path)
  validate_base_path(base_path)
  vim.call("trust#path#save", base_path)
end

--- Returns `true` if the path is trusted.
---
---@param path string Path to a workspace.
---@return boolean `true` if the path is trusted, `false` otherwise.
function path.is_allowed(path)
  validate { path = { path, "string" } }
  return vim.call("trust#path#is_allowed", path)
end

--- Returns the raw trust status of a path.
---
--- Unlike |trust.is_allowed()|, this does not respect the trust status of
--- ancestor paths.
---
---@return boolean|nil `true` if the path is explicitly marked as trusted,
--- `false` if marked as distrusted, `nil` otherwise.
function path.get(path)
  validate { path = { path, "string" } }
  return from_vim(vim.call("trust#path#get", path))
end

--- Returns the list of (dis)trusted workspaces as an array of arrays, whose
--- first element is a list of trusted workspaces and the second is a list of
--- distrusted workspaces.
---
--- If the trust status is modified between the iterator function calls, its
--- return value is unspecified.
---
---@return table List of (dis)trusted paths.
function path.workspaces()
  return vim.call("trust#path#workspaces")
end

return path
