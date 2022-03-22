let g:trust#gpg#never = -5
let g:trust#gpg#revoked = -4
let g:trust#gpg#expired = -3
let g:trust#gpg#err = -2
let g:trust#gpg#unknown = -1
let g:trust#gpg#undefined = 0
let g:trust#gpg#marginal = 1
let g:trust#gpg#full = 2
let g:trust#gpg#ultimate = 3

lockvar
  \ g:trust#gpg#never
  \ g:trust#gpg#revoked
  \ g:trust#gpg#expired
  \ g:trust#gpg#err
  \ g:trust#gpg#unknown
  \ g:trust#gpg#undefined
  \ g:trust#gpg#marginal
  \ g:trust#gpg#full
  \ g:trust#gpg#ultimate

let s:validities = {
  \'NEVER': g:trust#gpg#never,
  \'N': g:trust#gpg#never,
  \'REVOKED': g:trust#gpg#revoked,
  \'R': g:trust#gpg#revoked,
  \'EXPIRED': g:trust#gpg#expired,
  \'E': g:trust#gpg#expired,
  \'ERR': g:trust#gpg#err,
  \'?': g:trust#gpg#err,
  \'UNKNOWN': g:trust#gpg#unknown,
  \'-': g:trust#gpg#unknown,
  \'UNDEFINED': g:trust#gpg#undefined,
  \'UNDEF': g:trust#gpg#undefined,
  \'Q': g:trust#gpg#undefined,
  \'MARGINAL': g:trust#gpg#marginal,
  \'M': g:trust#gpg#marginal,
  \'FULL': g:trust#gpg#full,
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
