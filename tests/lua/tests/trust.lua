local trust = require("trust")

trust.clear()

trust.allow(root .. path { "home", "me" })
trust.deny(root .. path { "home", "me", "workspace", "forks" })

assert(not trust.is_allowed(root))
assert(not trust.is_allowed(root .. path { "home" }))
assert(trust.is_allowed(root .. path { "home", "me" }))
assert(trust.is_allowed(root .. path { "home", "me", "workspace" }))
assert(
  not trust.is_allowed(root .. path { "home", "me", "workspace", "forks" })
)
assert(
  not trust.is_allowed(
    root .. path { "home", "me", "workspace", "forks", "some_repository" }
  )
)

local ws = trust.workspaces()
local w, s = ws()
assert_eq(w, resolve(root .. path { "home", "me" }))
assert_eq(s, true)
w, s = ws()
assert_eq(w, resolve(root .. path { "home", "me", "workspace", "forks" }))
assert_eq(s, false)
assert_eq(ws(), nil)

trust.clear()

trust.allow("")
assert_eq(trust.get(getcwd()), true)

-- `load_state` should overwrite current status:
trust.load_state { allow = null, deny = null }
assert_eq(trust.workspaces()(), nil)

trust.allow(root)
trust.deny(root .. path { "foo" })

-- Should be able to handle `string` and `file`.
local tmpname = os.tmpname()
local tmpfile = io.tmpfile()

trust.save_state { allow = tmpname, deny = tmpfile }

local allowlist = io.open(tmpname)
assert_eq(allowlist:read("*a"), root .. "\n")
assert(allowlist:close())
assert(tmpfile:seek("set", 0))
assert_eq(tmpfile:read("*a"), root .. path { "foo" } .. "\n")
assert(tmpfile:seek("set", 0))

trust.load_state { allow = tmpfile, deny = tmpname }
assert(os.remove(tmpname))
assert(tmpfile:close())

assert_eq(trust.get(root .. path { "foo" }), true)
assert_eq(trust.get(root), false)
