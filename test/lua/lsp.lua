if not vim.lsp then
  return true
end

-- selene: allow(undefined_variable)
local assert_eq = assert_eq
-- selene: allow(undefined_variable)
local root = root
-- selene: allow(undefined_variable)
local path = path

local trust = require("trust")
local lsp = require("trust.lsp")

trust.clear()
lsp.safe_servers = {}

-- Test `hook_start_client()`:

-- Terribly sorry about doing the horrible reassign-a-global thing (again).
function vim.lsp.start_client()
  return true
end

lsp.hook_start_client()

-- Should block every call by default:
assert(not vim.lsp.start_client {
  name = "foo",
  root_dir = root .. path { "some", "path" },
})
assert_eq(lsp.last_root_dir, root .. path { "some", "path" })

trust.allow(root .. "some")
assert(vim.lsp.start_client {
  name = "foo",
  root_dir = root .. path { "some", "path" },
})

lsp.safe_servers = { "safe_ls" }
assert(vim.lsp.start_client {
  name = "safe_ls",
  root_dir = root .. path { "another", "path" },
})
assert_eq(lsp.last_root_dir, root .. path { "another", "path" })

-- Test metatable behaviors:

-- `safe_servers.*` should be `boolean`:
assert_eq(lsp.safe_servers.safe_ls, true)
assert_eq(lsp.safe_servers.random_ls, false)

-- Setting `boolean` values should work as well:
lsp.safe_servers.another_ls = true
assert_eq(lsp.safe_servers.another_ls, true)
lsp.safe_servers.another_ls = false
assert_eq(lsp.safe_servers.another_ls, false)

-- Should refuse to set other values:
assert(not pcall(function()
  lsp.safe_servers.another_ls = 1
end))
assert_eq(lsp.safe_servers.another_ls, false)
assert(not pcall(function()
  lsp.safe_servers = { 1 }
end))
assert_eq(lsp.safe_servers.another_ls, false)

-- Shold be unable to inspect the table directly:
assert(vim.deep_equal(lsp.safe_servers, {}))

local iter = lsp.safe_servers_pairs()
assert_eq(iter(), "safe_ls")
assert_eq(iter(), nil)

assert(vim.deep_equal(lsp.safe_servers_array(), { "safe_ls" }))

-- Should refuse to set `last_root_dir`:
assert(not pcall(function()
  lsp.last_root_dir = root .. "some-random-path"
end))
assert(lsp.last_root_dir ~= root .. "some-random-path")
