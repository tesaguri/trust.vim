local trust = require("trust")

trust.clear()

trust.trust(root .. path { "home", "me" })
trust.distrust(root .. path { "home", "me", "workspace", "forks" })

assert(not trust.is_trusted(root))
assert(not trust.is_trusted(root .. path { "home" }))
assert(trust.is_trusted(root .. path { "home", "me" }))
assert(trust.is_trusted(root .. path { "home", "me", "workspace" }))
assert(
  not trust.is_trusted(root .. path { "home", "me", "workspace", "forks" })
)
assert(
  not trust.is_trusted(
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

-- Should be no-op:
trust.undistrust(root .. path { "home", "me" })
trust.untrust(root .. path { "home", "me", "workspace", "forks" })

assert_eq(trust.get(resolve(root .. path { "home", "me" })), true)
assert_eq(
  trust.get(resolve(root .. path { "home", "me", "workspace", "forks" })),
  false
)

trust.untrust(root .. path { "home", "me" })
trust.undistrust(root .. path { "home", "me", "workspace", "forks" })
assert_eq(trust.workspaces()(), nil)

trust.clear()

trust.trust("")
assert_eq(trust.get(getcwd()), true)

-- `load_state` should overwrite current status:
trust.load_state { trust = null, distrust = null }
assert_eq(trust.workspaces()(), nil)

trust.trust(root)
trust.distrust(root .. path { "foo" })

-- Should be able to handle `string` and `file`.
local tmpname = os.tmpname()
local tmpfile = io.tmpfile()

trust.save_state { trust = tmpname, distrust = tmpfile }

local trust_file = io.open(tmpname)
assert_eq(trust_file:read("*a"), root .. "\n")
assert(trust_file:close())
assert(tmpfile:seek("set", 0))
assert_eq(tmpfile:read("*a"), root .. path { "foo" } .. "\n")
assert(tmpfile:seek("set", 0))

trust.load_state { trust = tmpfile, distrust = tmpname }
assert(os.remove(tmpname))
assert(tmpfile:close())

assert_eq(trust.get(root .. path { "foo" }), true)
assert_eq(trust.get(root), false)
