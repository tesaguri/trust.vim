let s:save_cpo = &cpo
set cpo&vim

unlockvar
  \ g:trust#gpg#revoked
  \ g:trust#gpg#err
  \ g:trust#gpg#unknown
  \ g:trust#gpg#expired
  \ g:trust#gpg#undefined
  \ g:trust#gpg#never
  \ g:trust#gpg#marginal
  \ g:trust#gpg#full
  \ g:trust#gpg#ultimate

let g:trust#gpg#revoked = -2
let g:trust#gpg#err = -1
let g:trust#gpg#unknown = 0
let g:trust#gpg#expired = 1
let g:trust#gpg#undefined = 2
let g:trust#gpg#never = 3
let g:trust#gpg#marginal = 4
let g:trust#gpg#full = 5
let g:trust#gpg#ultimate = 6

lockvar
  \ g:trust#gpg#revoked
  \ g:trust#gpg#err
  \ g:trust#gpg#unknown
  \ g:trust#gpg#expired
  \ g:trust#gpg#undefined
  \ g:trust#gpg#never
  \ g:trust#gpg#marginal
  \ g:trust#gpg#full
  \ g:trust#gpg#ultimate

let s:validities = {
  \'REVOKED': g:trust#gpg#revoked,
  \'R': g:trust#gpg#revoked,
  \'ERR': g:trust#gpg#err,
  \'?': g:trust#gpg#err,
  \'UNKNOWN': g:trust#gpg#unknown,
  \'-': g:trust#gpg#unknown,
  \'EXPIRED': g:trust#gpg#expired,
  \'E': g:trust#gpg#expired,
  \'UNDEFINED': g:trust#gpg#undefined,
  \'UNDEF': g:trust#gpg#undefined,
  \'Q': g:trust#gpg#undefined,
  \'NEVER': g:trust#gpg#never,
  \'N': g:trust#gpg#never,
  \'MARGINAL': g:trust#gpg#marginal,
  \'M': g:trust#gpg#marginal,
  \'FULL': g:trust#gpg#full,
  \'FULLY': g:trust#gpg#full,
  \'F': g:trust#gpg#full,
  \'ULTIMATE': g:trust#gpg#ultimate,
  \'U': g:trust#gpg#ultimate,
  \}

function! trust#gpg#validity(value) abort
  if type(a:value) is# v:t_number
      \&& s:validities.NEVER <= a:value
      \&& a:value <= s:validities.ULTIMATE
    return a:value
  elseif type(a:value) is# v:t_string
    let l:v = get(s:validities, toupper(a:value), v:null)
    if l:v isnot# v:null
      return l:v
    endif
  endif
  throw 'trust#gpg:INVALID_VALIDITY: Invalid validity: '.string(a:value)
endfunction

function! trust#gpg#min_validity() abort
  if exists('g:trust#gpg#min_validity')
    return trust#gpg#validity(g:trust#gpg#min_validity)
  else
    return s:validities.MARGINAL
  endif
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
