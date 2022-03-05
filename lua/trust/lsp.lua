-- Utilities for controlling NeoVim's `vim.lsp` attach behavior based on the
-- workspaces' trust statuses.

local M = {}
local mt = {}

local trust = require("trust")

local safe_servers_mt = {}
--- Handle of a set of servers that are run regardless of the workspace's trust
--- status.
---
--- This is not an ordinary dictionary and you can only inspect its content
--- through indexing.
---
--- Examples: >
--- local trust_lsp = require("trust.lsp")
---
--- -- Set an individual server:
--- trust_lsp.safe_servers.dhall_lsp_server = true
---
--- -- Set multiple servers at once:
--- trust_lsp.safe_servers = { "dhall_lsp_server" }
---
--- -- You cannot use `next` on it:
--- assert(next(trust_lsp.safe_servers) == nil)
--- -- But you can index it by the server name:
--- assert(trust_lsp.safe_servers.dhall_lsp_server == true)
--- -- or use the `safe_servers_pairs()` iterator function:
--- assert(trust_lsp.safe_servers_pairs()() == "dhall_lsp_server")
--- <
local safe_servers = {}

--- The value of `root_dir` config key that were passed in the last call of the
--- hooked version of `vim.lsp.start_client`.
local last_root_dir

local hooked_start_client

--- Overwrites `vim.lsp.start_client` to make it respect the workspace trust
--- statuses.
---
---@return function|nil The old `vim.lsp.start_client` function if it has not
--- been hooked already, `nil` otherwise.
function M.hook_start_client()
  local old = vim.lsp.start_client
  if old == hooked_start_client then
    return
  end

  local function start_client(config)
    -- `lspconfig` sets `root_dir` to `nil` in single file mode.
    -- Fall back to `cmd_cwd` in that case.
    local root_dir = config.root_dir or config.cmd_cwd
    if not root_dir then
      return
    end
    last_root_dir = root_dir
    if rawget(safe_servers, config.name) or trust.is_allowed(root_dir) then
      return old(config)
    end
  end
  hooked_start_client = start_client
  -- selene: allow(incorrect_standard_library_use)
  vim.lsp.start_client = start_client

  return old
end

--- Returns the list of |safe_servers| as an array of server name.
---
---@return table Array of the safe servers' names.
function M.safe_servers_array()
  return vim.tbl_keys(safe_servers)
end

--- Returns an iterator function that, each time it is called, returns the name
--- of a |safe_servers| and `true`.
---
---@return function An iterator over safe server's names.
function M.safe_servers_pairs()
  -- We don't simply return `pairs(safe_servers)` because it also returns the
  -- original table, which we don't want to expose.
  local s = safe_servers
  local var
  return function()
    var = next(s, var)
    return var, true
  end
end

-- Metatable definitions:

local index = {}

function mt.__index(_, key)
  local handler = index[key]
  return handler and handler()
end

function index.safe_servers()
  return setmetatable({}, safe_servers_mt)
end

function index.last_root_dir()
  return last_root_dir
end

local newindex = {}

function mt.__newindex(_, key, value)
  local handler = newindex[key]
  return handler and handler(value)
end

function newindex.safe_servers(value)
  vim.validate {
    safe_servers = {
      value,
      "table",
    },
  }
  local new = {}
  for k, v in pairs(value) do
    if type(k) == "number" and type(v) == "string" then
      new[v] = true
    elseif type(k) == "string" and type(v) == "boolean" then
      if v then
        new[k] = true
      end
    else
      assert(
        false,
        "safe_servers: expected dictionary `{ string = boolean }` or array of strings"
      )
    end
  end
  safe_servers = new
  return true
end

function newindex.last_root_dir()
  error("Refusing to set `last_root_dir` directly")
end

function safe_servers_mt.__index(_, key)
  return safe_servers[key] == true
end

function safe_servers_mt.__newindex(_, key, value)
  assert(
    type(key) == "string",
    "safe_servers: expected string key, got " .. type(key)
  )
  vim.validate { [key] = { value, "boolean", true } }
  safe_servers[key] = value or nil
  return true
end

return setmetatable(M, mt)
