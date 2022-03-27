---@private
local gpg = {}

local revoked = vim.call("trust#gpg#validity", "REVOKED")
local err = vim.call("trust#gpg#validity", "ERR")
local unknown = vim.call("trust#gpg#validity", "UNKNOWN")
local expired = vim.call("trust#gpg#validity", "EXPIRED")
local undefined = vim.call("trust#gpg#validity", "UNDEFINED")
local never = vim.call("trust#gpg#validity", "NEVER")
local marginal = vim.call("trust#gpg#validity", "MARGINAL")
local full = vim.call("trust#gpg#validity", "FULL")
local ultimate = vim.call("trust#gpg#validity", "ULTIMATE")

gpg.revoked = revoked
gpg.err = err
gpg.unknown = unknown
gpg.expired = expired
gpg.undefined = undefined
gpg.never = never
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
