local util = require("testutil")

local suite = {}

if not vim.lsp then
  function suite._()
    vim.call("themis#helper", "assert").skip("`vim.lsp` is not available")
  end
  return util.dict(suite)
end

local trust = require("trust")
local lsp = require("trust.lsp")

function suite.after_each()
  trust.clear()
  lsp.safe_servers = {}
end

function suite.hook_start_client()
  -- Terribly sorry about doing the horrible reassign-a-global thing (again).
  function vim.lsp.start_client()
    return true
  end

  lsp.hook_start_client()

  -- Should block every call by default:
  assert(not vim.lsp.start_client {
    name = "foo",
    root_dir = util.root .. util.path { "some", "path" },
  })
  util.assert_eq(lsp.last_root_dir, util.root .. util.path { "some", "path" })

  trust.allow(util.root .. "some")
  assert(vim.lsp.start_client {
    name = "foo",
    root_dir = util.root .. util.path { "some", "path" },
  })

  lsp.safe_servers = { "safe_ls" }
  assert(vim.lsp.start_client {
    name = "safe_ls",
    root_dir = util.root .. util.path { "another", "path" },
  })
  util.assert_eq(
    lsp.last_root_dir,
    util.root .. util.path { "another", "path" }
  )
end

function suite.metatable()
  lsp.safe_servers = { "safe_ls" }

  -- `safe_servers.*` should be `boolean`:
  util.assert_eq(lsp.safe_servers.safe_ls, true)
  util.assert_eq(lsp.safe_servers.random_ls, false)

  -- Setting `boolean` values should work as well:
  lsp.safe_servers.another_ls = true
  util.assert_eq(lsp.safe_servers.another_ls, true)
  lsp.safe_servers.another_ls = false
  util.assert_eq(lsp.safe_servers.another_ls, false)

  -- Should refuse to set other values:
  assert(not pcall(function()
    lsp.safe_servers.another_ls = 1
  end))
  util.assert_eq(lsp.safe_servers.another_ls, false)
  assert(not pcall(function()
    lsp.safe_servers = { 1 }
  end))
  util.assert_eq(lsp.safe_servers.another_ls, false)

  -- Shold be unable to inspect the table directly:
  assert(vim.deep_equal(lsp.safe_servers, {}))

  local iter = lsp.safe_servers_pairs()
  util.assert_eq(iter(), "safe_ls")
  util.assert_eq(iter(), nil)

  assert(vim.deep_equal(lsp.safe_servers_array(), { "safe_ls" }))

  -- Should refuse to set `last_root_dir`:
  assert(not pcall(function()
    lsp.last_root_dir = util.root .. "some-random-path"
  end))
  assert(lsp.last_root_dir ~= util.root .. "some-random-path")
end

return util.dict(suite)
