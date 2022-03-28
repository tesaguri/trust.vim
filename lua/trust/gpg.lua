local gpg = {}

--- Indicates the validity value of `revoked`.
gpg.revoked = vim.call("trust#gpg#validity", "REVOKED")

--- Indicates the validity value of `err`.
gpg.err = vim.call("trust#gpg#validity", "ERR")

--- Indicates the validity value of `unknown`.
gpg.unknown = vim.call("trust#gpg#validity", "UNKNOWN")

--- Indicates the validity value of `expired`.
gpg.expired = vim.call("trust#gpg#validity", "EXPIRED")

--- Indicates the validity value of `undefined`.
gpg.undefined = vim.call("trust#gpg#validity", "UNDEFINED")

--- Indicates the validity value of `never`.
gpg.never = vim.call("trust#gpg#validity", "NEVER")

--- Indicates the validity value of `marginal`.
gpg.marginal = vim.call("trust#gpg#validity", "MARGINAL")

--- Indicates the validity value of `full`.
gpg.full = vim.call("trust#gpg#validity", "FULL")

--- Indicates the validity value of `ultimate`.
gpg.ultimate = vim.call("trust#gpg#validity", "ULTIMATE")

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
