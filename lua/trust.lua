local M = {}

local getcwd = vim.funcref("getcwd")
local has = vim.funcref("has")
local mkdir = vim.funcref("mkdir")
local resolve = vim.funcref("resolve")
local stdpath = vim.funcref("stdpath")

-- Polyfill NeoVim-only APIs:

local gsplit
if vim.gsplit then
  gsplit = vim.gsplit
else
  function gsplit(s, sep, _plain)
    local list = vim.funcref("split")(s, sep, true)
    local i = 0
    return function()
      i = i + 1
      return list[i]
    end
  end
end

local validate
if vim.validate then
  validate = vim.validate
else
  function validate(opt)
    for name, spec in pairs(opt) do
      local arg = spec[1]
      local type_name = spec[2]
      local optional = spec[3]

      if type(arg) ~= type_name and not (optional and arg == nil) then
        error(name .. ": expected " .. type_name .. ", got " .. type(arg))
      end
    end
  end
end

-- Common utilities:

local sep
local use_drive_letter
if has("win32") ~= 0 then
  sep = "\\"
  use_drive_letter = true
else
  sep = "/"
  use_drive_letter = false
end
local trust_key = sep .. "trust"

-- A tree representing the file system and storing trust statuses of workspaces.
local tree = {}

local function is_absolute(path)
  if use_drive_letter then
    return path:match("^[A-Za-z]:")
  else
    return path:sub(1, 1) == sep
  end
end

local function path_components(path)
  if not is_absolute(path) then
    path = getcwd() .. sep .. path
  end

  path = resolve(path):gsub(sep .. sep .. "+", sep)

  if path:sub(-1) == sep then
    -- Remove trailing path separator.
    path = path:sub(1, -2)
  end

  if use_drive_letter and path:match("^[a-z]") then
    path = path:sub(1, 1):upper() .. path:sub(2)
  else
    -- Remove leading path separator.
    path = path:sub(2)
  end

  return gsplit(path, sep, true)
end

--- Get the tree node for a path.
local function get_node(path, node)
  node = node or tree
  for comp in path_components(path) do
    node = node[comp]
    if not node then
      return
    end
  end
  return node
end

--- Gets the tree node for a path, creating a new node if one does not exist.
local function dig(path, node)
  node = node or tree
  for comp in path_components(path) do
    local next = node[comp]
    if next then
      node = next
    else
      next = {}
      node[comp] = next
      node = next
    end
  end
  return node
end

-- Trust management:

--- Marks a path as trusted.
---
--- Workspaces at the path or its descendants (up to a path explicitly marked
--- as distrusted) will be trusted.
---
---@param path string The path to trust.
---@return boolean The original status value of the node before this function is
--- called.
function M.allow(path)
  validate { path = { path, "string" } }
  local node = dig(path)
  local original = node[trust_key]
  node[trust_key] = true
  return original
end

--- Marks a path as distrusted.
---
--- Workspaces at the path or its descendants (up to a path explicitly marked
--- as trusted, if any) will be untrusted.
---
---@param path string The path to distrust.
---@return boolean The original status value of the node before this function is
--- called.
function M.deny(path)
  validate { path = { path, "string" } }
  local node = dig(path)
  local original = node[trust_key]
  node[trust_key] = false
  return original
end

--- Sets the raw trust status of a path.
---
---@param path string The path to set trust status.
---@param status boolean|nil Trust status value. `true` to trust, `false` to
--- distrust, `nil` to unset.
---@return boolean The original status value of the node before this function is
--- called.
function M.set(path, status)
  validate { path = { path, "string" }, status = { status, "boolean", true } }
  if status == nil then
    return M.remove(path)
  else
    local node = dig(path)
    local original = node[trust_key]
    node[trust_key] = status
    return original
  end
end

--- Removes the marker of (dis)trust of a path if it has been marked with
--- |allow()| or |deny()|.
---
---@param path string The path to unmark.
function M.remove(path)
  validate { path = { path, "string" } }
  local node = get_node(path)
  if node then
    local original = node[trust_key]
    node[trust_key] = nil
    return original
  end
end

--- Clears the status of (dis)trust of all paths.
function M.clear()
  tree = {}
end

-- Persistent storage management:

local function file_paths(base_path)
  local default
  local function default_base()
    if not default then
      default = stdpath("data") .. sep .. "trust"
    end
    return default
  end

  base_path = base_path or default_base()

  if type(base_path) == "string" then
    return base_path .. sep .. "allow.txt", base_path .. sep .. "deny.txt"
  elseif type(base_path) == "table" then
    return base_path.allow or default_base() .. sep .. "allow.txt",
      base_path.deny or default_base() .. sep .. "deny.txt"
  end
end

local empty_file = {}

local function empty_iter() end

function empty_file.lines()
  return empty_iter
end

function empty_file.close()
  return true
end

local open_ignore_non_existent
if has("unix") ~= 0 or has("win32") ~= 0 then
  function open_ignore_non_existent(filename)
    local f, msg, errno = io.open(filename)
    if f then
      return f
    elseif errno == 2 then
      -- `ENOENT` on Unix and `ERROR_FILE_NOT_FOUND` on Windows
      return empty_file
    else
      return f, msg, errno
    end
  end
else
  open_ignore_non_existent = io.open
end

--- Loads trust statuses from files.
---
--- Overwrites the on-memory trust statuses.
---
---@param base_path string|table|nil String of the path to a directory
--- containing the status files or a table with `allow` and `deny` keys, each of
--- whose value is a file object or a string of the path to a status file.
--- Defaults to `stdpath("data")."/trust"` (requires NeoVim).
function M.load_state(base_path)
  local allowlist, denylist = file_paths(base_path)
  local al_is_path = io.type(allowlist) == nil
  local dl_is_path = io.type(denylist) == nil

  if not io.type(allowlist) then
    allowlist = assert(open_ignore_non_existent(allowlist))
  end
  if not io.type(denylist) then
    denylist = assert(open_ignore_non_existent(denylist))
  end

  local new_tree = {}

  for path in allowlist:lines() do
    dig(path, new_tree)[trust_key] = true
  end
  if al_is_path then
    assert(allowlist:close())
  end

  for path in denylist:lines() do
    dig(path, new_tree)[trust_key] = false
  end
  if dl_is_path then
    assert(denylist:close())
  end

  tree = new_tree

  return true
end

--- Saves the on-memory trust statuses into files.
---
---@param base_path string|table|nil String of the path to a directory to save
--- the status files in or a table with `allow` and `deny` keys, each of whose
--- value is a file object or a string of the path to save the status file.
--- Defaults to `stdpath("data")."/trust"` (requires NeoVim).
function M.save_state(base_path)
  local allowlist, denylist = file_paths(base_path)
  local al_is_path = io.type(allowlist) == nil
  local dl_is_path = io.type(denylist) == nil

  if type(base_path) == "string" then
    mkdir(base_path, "p")
  end
  if al_is_path then
    allowlist = assert(io.open(allowlist, "w"))
    allowlist:setvbuf("full")
  end
  if dl_is_path then
    denylist = assert(io.open(denylist, "w"))
    denylist:setvbuf("full")
  end

  for path, trust in M.workspaces() do
    if trust then
      assert(allowlist:write(path))
      -- Using LF as delimiter, which is most easily splittable with Lua's `io`
      -- module, although it is also a valid file name character (NUL would be
      -- ideal in that regard?).
      assert(allowlist:write("\n"))
    else
      assert(denylist:write(path))
      assert(denylist:write("\n"))
    end
  end

  if al_is_path then
    assert(allowlist:close())
  else
    assert(allowlist:flush())
  end
  if dl_is_path then
    assert(denylist:close())
  else
    assert(denylist:flush())
  end

  return true
end

-- Trust query:

--- Returns `true` if the path is trusted.
---
---@param path string Path to a workspace.
---@return boolean `true` if the path is trusted, `false` otherwise.
function M.is_allowed(path)
  validate { path = { path, "string" } }

  local node = tree
  local ret = not not node.trust

  for comp in path_components(path) do
    node = node[comp]
    if node then
      if node[trust_key] then
        ret = true
      elseif node[trust_key] == false then
        ret = false
      end
    else
      return ret
    end
  end

  return ret
end

--- Returns the raw trust status of a path.
---
--- Unlike |is_allowed()|, this does not respect the trust status of ancestor
--- paths.
---
---@return boolean|nil `true` if the path is explicitly marked as trusted,
--- `false` if marked as distrusted, `nil` otherwise.
function M.get(path)
  validate { path = { path, "string" } }
  local node = get_node(path)
  if node then
    return node[trust_key]
  end
end

local function walk(node, path)
  local trust = node[trust_key]
  if trust ~= nil then
    if not (use_drive_letter and path == "") then
      local key = path == "" and sep or path
      coroutine.yield(key, trust)
    end
  end
  for name, child in pairs(node) do
    if name:sub(1, 1) ~= sep then
      local child_path = path .. sep .. name
      walk(child, child_path)
    end
  end
end

--- Returns an iterator function that, each time it is called, returns a path
--- that has been marked as (dis)trusted as the first value and its trust status
--- as boolean (`true` if trusted, `false` if distrusted) as the second value.
---
--- If the trust status is modified between the iterator function calls, its
--- return value is unspecified.
---
---@return function An iterator over (dis)trusted paths and their trust status.
function M.workspaces()
  local node = tree
  return coroutine.wrap(function()
    walk(node, "")
  end)
end

return M
