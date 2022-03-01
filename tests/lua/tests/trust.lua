local trust = require("trust")

trust.clear()

trust.trust("/home/me")
trust.distrust("/home/me/workspace/forks")

assert(not trust.is_trusted("/"))
assert(not trust.is_trusted("/home"))
assert(trust.is_trusted("/home/me"))
assert(trust.is_trusted("/home/me/workspace"))
assert(not trust.is_trusted("/home/me/workspace/forks"))
assert(not trust.is_trusted("/home/me/workspace/forks/some_repository"))

local ws = trust.workspaces()
local w, s = ws()
assert_eq(w, resolve("/home/me"))
assert_eq(s, true)
w, s = ws()
assert_eq(w, resolve("/home/me/workspace/forks"))
assert_eq(s, false)
assert_eq(ws(), nil)

-- Should be no-op:
trust.undistrust("/home/me")
trust.untrust("/home/me/workspace/forks")

assert_eq(trust.get(resolve("/home/me")), true)
assert_eq(trust.get(resolve("/home/me/workspace/forks")), false)

trust.untrust("/home/me")
trust.undistrust("/home/me/workspace/forks")
assert_eq(trust.workspaces()(), nil)

trust.clear()

trust.trust("")
assert_eq(trust.get(getcwd()), true)

-- `load_state` should overwrite current status:
trust.load_state { trust = "/dev/null", distrust = "/dev/null" }
assert_eq(trust.workspaces()(), nil)

trust.trust("/")
trust.distrust("/foo")

-- Should be able to handle `string` and `file`.
local path = os.tmpname()
local file = io.tmpfile()

trust.save_state { trust = path, distrust = file }

local trust_file = io.open(path)
assert_eq(trust_file:read("*a"), "/\n")
assert(trust_file:close())
assert(file:seek("set", 0))
assert_eq(file:read("*a"), "/foo\n")
assert(file:seek("set", 0))

trust.load_state { trust = file, distrust = path }
assert(os.remove(path))
assert(file:close())

assert_eq(trust.get("/foo"), true)
assert_eq(trust.get("/"), false)
