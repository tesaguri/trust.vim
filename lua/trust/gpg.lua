---@private
local gpg = {}

--- Indicates the validity value of `revoked`.
local revoked = vim.call("trust#gpg#validity", "REVOKED")

--- Indicates the validity value of `err`.
local err = vim.call("trust#gpg#validity", "ERR")

--- Indicates the validity value of `unknown`.
local unknown = vim.call("trust#gpg#validity", "UNKNOWN")

--- Indicates the validity value of `expired`.
local expired = vim.call("trust#gpg#validity", "EXPIRED")

--- Indicates the validity value of `undefined`.
local undefined = vim.call("trust#gpg#validity", "UNDEFINED")

--- Indicates the validity value of `never`.
local never = vim.call("trust#gpg#validity", "NEVER")

--- Indicates the validity value of `marginal`.
local marginal = vim.call("trust#gpg#validity", "MARGINAL")

--- Indicates the validity value of `full`.
local full = vim.call("trust#gpg#validity", "FULL")

--- Indicates the validity value of `ultimate`.
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

--- Converts a validity value representation to a number representation.
---
--- When a number is passed, returns it as-is if it is one of the numbers listed
--- in "Return" section below, or throws an exception otherwise.
---
--- Regarding the ordering of the returned value, it is guaranteed that
--- `ultimate > full > marginal` holds and `marginal`  compares greater than
--- other validity values, but any other comparison is unspecified and is
--- subject to change at any time.
---
---@param value string|number If `string`, one of (case-insensitive):
--- - `-` or `unknown`
--- - `e` or `expired`
--- - `q` or `undefined`
--- - `n` or `never`
--- - `m` or `marginal`
--- - `f` or `full`
--- - `u` or `ultimate`
--- - `r` or `revoked`
--- - `?` or `err`
--- <p></p><!-- FIXME: I don't know the right way to tell Doxygen to finish the
--- item list but not to finish the parameter description... -->
--- See also the man page for `gpg(1)`.
---@return number One of |gpg.unknown|, |gpg.expired|, |gpg.undefined|,
--- |gpg.never|, |gpg.marginal|, |gpg.full|, |gpg.ultimate|, |gpg.revoked|
--- or |gpg.err|.
function gpg.validity(value)
  return vim.call("trust#gpg#validity", value)
end

--- Returns `gpg.validity(vim.g["trust#gpg#min_validity"])` or |gpg.marginal| if
--- `g:trust#gpg#min_validity` is unset.
---
--- This can be used by trust sources as a threshold to determine if a signature
--- is considered trustworthy.
function gpg.min_validity()
  return vim.call("trust#gpg#min_validity")
end

return gpg
