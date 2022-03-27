local trust = {}

-- Re-export `trust.path.*` for backwards compatibility:
for name, f in pairs(require("trust.path")) do
  trust[name] = f
end

---@private
local validate
if vim.validate then
  validate = vim.validate
else
  ---@private
  function validate(opt)
    for name, spec in pairs(opt) do
      local arg = spec[1]
      local type_name = spec[2]

      if type(arg) ~= type_name then
        error(name .. ": expected " .. type_name .. ", got " .. type(arg), 2)
      end
    end
  end
end

--- Returns `true` if the path is trusted.
---
---@param path string Path to a workspace.
---@return boolean `true` if the path is trusted, `false` otherwise.
function trust.is_allowed(path)
  validate { path = { path, "string" } }
  return vim.call("trust#is_allowed", path)
end

return trust
