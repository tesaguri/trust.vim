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

-- A tree representing the file system and storing trust statuses of workspaces.
local tree = {}

local function path_components(path)
  if path:byte(1) ~= ("/"):byte(1) then
    path = getcwd() .. "/" .. path
  end
  path = resolve(path):gsub("/+", "/"):gsub("/$", "")
  return gsplit(string.sub(path, 2), "/", true)
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
function M.trust(path)
  validate { path = { path, "string" } }
  local node = dig(path)
  local original = node["/trust"]
  node["/trust"] = true
  return original
end

--- Removes the marker of trust of a path if it has been marked with
--- |trust()|.
---
---@param path string The path to unmark.
---@return
function M.untrust(path)
  validate { path = { path, "string" } }
  local node = get_node(path)
  local original = node and node["/trust"]
  if original then
    node["/trust"] = nil
    return original
  end
end

--- Marks a path as distrusted.
---
--- Workspaces at the path or its descendants (up to a path explicitly marked
--- as trusted, if any) will be untrusted.
---
---@param path string The path to distrust.
function M.distrust(path)
  validate { path = { path, "string" } }
  local node = dig(path)
  local original = node["/trust"]
  node["/trust"] = false
  return original
end

--- Removes the marker of distrust of a path if it has been marked with
--- |distrust()|.
---
---@param path string The path to unmark.
function M.undistrust(path)
  validate { path = { path, "string" } }
  local node = get_node(path)
  local original = node and node["/trust"]
  if original == false then
    node["/trust"] = nil
  end
  return original
end

--- Sets the raw trust status of a path.
function M.set(path, status)
  validate { path = { path, "string" }, status = { status, "boolean", true } }
  if status == nil then
    return M.remove(path)
  else
    local node = dig(path)
    local original = node["/trust"]
    node["/trust"] = status
    return original
  end
end

--- Removes the marker of (dis)trust of a path if it has been marked with
--- |trust()| or |distrust()|.
---
---@param path string The path to unmark.
function M.remove(path)
  validate { path = { path, "string" } }
  local node = get_node(path)
  if node then
    local original = node["/trust"]
    node["/trust"] = nil
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
      default = stdpath("data") .. "/trust"
    end
    return default
  end

  base_path = base_path or default_base()

  if type(base_path) == "string" then
    return base_path .. "/trust.txt", base_path .. "/distrust.txt"
  elseif type(base_path) == "table" then
    return base_path.trust or default_base() .. "/trust.txt",
      base_path.distrust or default_base() .. "/distrust.txt"
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

if has("unix") ~= 0 then
  function open_ignore_non_existent(filename)
    local f, msg, errno = io.open(filename)
    if f then
      return f
    elseif errno == 2 then -- ENOENT
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
--- containing the status files or a table with `trust` and `distrust` keys each
--- of whose value is a file object or a string of the path to a status file.
--- Defaults to `stdpath("data")."/trust"` (requires NeoVim).
function M.load_state(base_path)
  local trust_list, distrust_list = file_paths(base_path)
  local trust_is_path = io.type(trust_list) == nil
  local distrust_is_path = io.type(distrust_list) == nil

  if not io.type(trust_list) then
    trust_list = assert(open_ignore_non_existent(trust_list))
  end
  if not io.type(distrust_list) then
    distrust_list = assert(open_ignore_non_existent(distrust_list))
  end

  local new_tree = {}

  for path in trust_list:lines() do
    dig(path, new_tree)["/trust"] = true
  end
  if trust_is_path then
    assert(trust_list:close())
  end

  for path in distrust_list:lines() do
    dig(path, new_tree)["/trust"] = false
  end
  if distrust_is_path then
    assert(distrust_list:close())
  end

  tree = new_tree

  return true
end

--- Saves the on-memory trust statuses into files.
---
---@param base_path string|table|nit String of the path to a directory to save
--- the status files in or a table with `trust` and `distrust` keys each of
--- whose value is a file object or a string of the path to save the status
--- file. Defaults to `stdpath("data")."/trust"` (requires NeoVim).
function M.save_state(base_path)
  local trust_list, distrust_list = file_paths(base_path)
  local trust_is_path = io.type(trust_list) == nil
  local distrust_is_path = io.type(distrust_list) == nil

  if type(base_path) == "string" then
    mkdir(base_path, "p")
  end
  if trust_is_path then
    trust_list = assert(io.open(trust_list, "w"))
    trust_list:setvbuf("full")
  end
  if distrust_is_path then
    distrust_list = assert(io.open(distrust_list, "w"))
    distrust_list:setvbuf("full")
  end

  for path, trust in M.workspaces() do
    if trust then
      assert(trust_list:write(path))
      -- Using LF as delimiter, which is most easily splittable with Lua's `io`
      -- module, although it is also a valid file name character (NUL would be
      -- ideal in that regard?).
      assert(trust_list:write("\n"))
    else
      assert(distrust_list:write(path))
      assert(distrust_list:write("\n"))
    end
  end

  if trust_is_path then
    assert(trust_list:close())
  else
    assert(trust_list:flush())
  end
  if distrust_is_path then
    assert(distrust_list:close())
  else
    assert(distrust_list:flush())
  end

  return true
end

-- Trust query:

--- Returns `true` if the path is trusted.
---
---@param string Path to a workspace.
---@return `true` if the path is trusted, `false` otherwise.
function M.is_trusted(path)
  validate { path = { path, "string" } }

  local node = tree
  local ret = not not node.trust

  for comp in path_components(path) do
    node = node[comp]
    if node then
      if node["/trust"] then
        ret = true
      elseif node["/trust"] == false then
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
--- Unlike |is_trusted()|, this does not respect the trust status of ancestor
--- paths.
---
---@return boolean|nil `true` if the path is explicitly marked as trusted,
--- `false` if marked as distrusted, `nil` otherwise.
function M.get(path)
  validate { path = { path, "string" } }
  local node = get_node(path)
  if node then
    return node["/trust"]
  end
end

local function walk(node, path)
  local trust = node["/trust"]
  if trust ~= nil then
    local key = path == "" and "/" or path
    coroutine.yield(key, trust)
  end
  for name, child in pairs(node) do
    if name:byte(1) ~= ("/"):byte(1) then
      local child_path = path .. "/" .. name
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
function M.workspaces()
  local node = tree
  return coroutine.wrap(function()
    walk(node, "")
  end)
end

return M
