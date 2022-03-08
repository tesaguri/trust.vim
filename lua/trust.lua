local M = {}

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
        error(name .. ": expected " .. type_name .. ", got " .. type(arg), 2)
      end
    end
  end
end

local allow = vim.funcref("trust#allow")
function M.allow(path)
  validate { path = { path, "string" } }
  return allow(path)
end

local deny = vim.funcref("trust#deny")
function M.deny(path)
  validate { path = { path, "string" } }
  return deny(path)
end

local set = vim.funcref("trust#set")
function M.set(path, status)
  validate { path = { path, "string" }, status = { status, "boolean", true } }
  return set(path, status)
end

local remove = vim.funcref("trust#remove")
function M.remove(path)
  validate { path = { path, "string" } }
  return remove(path)
end

local clear = vim.funcref("trust#clear")
function M.clear()
  clear()
end

local function validate_base_path(base_path)
  if
    type(base_path) ~= "string"
    and type(base_path) ~= "table"
    and base_path ~= nil
  then
    error("base_path: expected string|table|nil, got " .. type(base_path), 2)
  end
end

local load = vim.funcref("trust#load")
function M.load(base_path)
  validate_base_path(base_path)
  load(base_path)
end

local save = vim.funcref("trust#save")
function M.save(base_path)
  validate_base_path(base_path)
  save(base_path)
end

local is_allowed = vim.funcref("trust#is_allowed")
function M.is_allowed(path)
  validate { path = { path, "string" } }
  return is_allowed(path)
end

local get = vim.funcref("trust#get")
function M.get(path)
  validate { path = { path, "string" } }
  return get(path)
end

local workspaces = vim.funcref("trust#workspaces")
function M.workspaces()
  return workspaces()
end

return M
