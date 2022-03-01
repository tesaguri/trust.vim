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
assert(not vim.lsp.start_client { name = "foo", root_dir = "/some/path" })
assert_eq(lsp.last_root_dir, "/some/path")

trust.trust("/some")
assert(vim.lsp.start_client { name = "foo", root_dir = "/some/path" })

lsp.safe_servers = { "safe_ls" }
assert(vim.lsp.start_client { name = "safe_ls", root_dir = "/another/path" })
assert_eq(lsp.last_root_dir, "/another/path")

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
assert_eq(
  pcall(function()
    lsp.safe_servers.another_ls = 1
  end),
  false
)
assert_eq(lsp.safe_servers.another_ls, false)
assert_eq(
  pcall(function()
    lsp.safe_servers = { 1 }
  end),
  false
)
assert_eq(lsp.safe_servers.another_ls, false)

-- Shold be unable to inspect the table directly:
assert(vim.deep_equal(lsp.safe_servers, {}))

local iter = lsp.safe_servers_pairs()
assert_eq(iter(), "safe_ls")
assert_eq(iter(), nil)

assert(vim.deep_equal(lsp.safe_servers_array(), { "safe_ls" }))

-- Should refuse to set `last_root_dir`:
assert_eq(
  pcall(function()
    lsp.last_root_dir = "/some/random/path"
  end),
  false
)
assert(lsp.last_root_dir ~= "/some/random/path")
