--# selene: allow(unused_variable)
--# selene: allow(unscoped_variables)
--# selene: deny(undefined_variable)

getcwd = vim.funcref("getcwd")
inspect = vim.inspect or tostring
resolve = vim.funcref("resolve")

local cmd = vim.cmd or vim.command
local has = vim.funcref("has")

function assert_eq(lhs, rhs)
  if lhs ~= rhs then
    error(
      "assertion failed: `" .. inspect(lhs) .. " == " .. inspect(rhs) .. "`",
      2
    )
  end
end

local scriptdir = debug.traceback():match(
  "^[^\n]*\n\t(.*)init.lua:%d+: in main chunk"
)
if scriptdir == "" then
  scriptdir = "."
end
cmd("set runtimepath^=" .. scriptdir)
cmd("set runtimepath^=" .. scriptdir .. "/..")

local s, e = pcall(function()
  require("tests.trust")
  if has("nvim") ~= 0 then
    require("tests.lsp")
  end
end)
if not s then
  print(inspect(e) .. "\n")
  cmd("cquit")
end
