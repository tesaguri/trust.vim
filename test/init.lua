--# selene: allow(unused_variable)
--# selene: allow(unscoped_variables)

print(_VERSION)
if jit then
  print(jit.version)
end

getcwd = vim.funcref("getcwd")
has = vim.funcref("has")
inspect = vim.inspect or tostring
resolve = vim.funcref("resolve")

local cmd = vim.cmd or vim.command
local glob = vim.funcref("glob")

local values
if vim.list then
  function values(list)
    return list()
  end
else
  function values(list)
    local k
    return function()
      local v
      k, v = next(list, k)
      return v
    end
  end
end

if has("win32") ~= 0 then
  root = "C:\\"
  null = "NUL"
  function path(comps)
    return table.concat(comps, "\\")
  end
else
  root = "/"
  null = "/dev/null"
  function path(comps)
    return table.concat(comps, "/")
  end
end
-- selene: allow(undefined_variable)
local path = path

function assert_eq(lhs, rhs)
  if lhs ~= rhs then
    error(
      "assertion failed: `" .. inspect(lhs) .. " == " .. inspect(rhs) .. "`",
      2
    )
  end
end

local scriptdir = debug.getinfo(1).source:match("@(.*)init.lua") or "."
if scriptdir == "" then
  scriptdir = "."
end

cmd("set runtimepath^=" .. resolve(path { scriptdir, ".." }))
cmd([[echo 'runtimepath: '.&runtimepath."\n"]])

local success = true
for chunk in
  values(glob(path { scriptdir .. "lua", "**", "*.lua" }, false, true))
do
  cmd("echon 'Running " .. chunk .. " ... '")
  local result, skipped = xpcall(function()
    return dofile(chunk)
  end, function(e)
    cmd([[echon "FAILED\n"]])
    if type(e) == "string" then
      print(e)
    else
      print(inspect(e))
    end
    print("\n")
  end)
  if skipped then
    cmd([[echon "skipped\n"]])
  elseif result then
    cmd([[echon "ok\n"]])
  else
    success = false
  end
end

print("\n")

if not success then
  cmd("cquit")
end
