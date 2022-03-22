---@private
local gpg = {}

local never = -3
local expired = -2
local unknown = -1
local undefined = 0
local marginal = 1
local full = 2
local ultimate = 3

gpg.never = never
gpg.expired = expired
gpg.unknown = unknown
gpg.undefined = undefined
gpg.marginal = marginal
gpg.full = full
gpg.ultimate = ultimate

---@private
local validity = vim.funcref("trust#gpg#validity")
function gpg.validity(value)
  return validity(value)
end

---@private
local f = vim.funcref("trust#gpg#min_validity")
function gpg.min_validity()
  return f()
end

return gpg
