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

function gpg.validity(value)
  return vim.call("trust#gpg#validity", value)
end

function gpg.min_validity()
  return vim.call("trust#gpg#min_validity")
end

return gpg
