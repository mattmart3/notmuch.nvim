let g:notmuch_mailroot = trim(system('notmuch config get database.mail_root'))
if v:shell_error != 0 || empty(g:notmuch_mailroot)
  echohl ErrorMsg
  echom 'notmuch.nvim: Failed to get database.mail_root from notmuch config'
  echohl None
  finish
endif

command -complete=custom,notmuch#CompSearchTerms -nargs=* NmSearch :call v:lua.require('notmuch').search_terms(<q-args>)
command -complete=custom,notmuch#CompAddress -nargs=* ComposeMail :call v:lua.require('notmuch.send').compose(<q-args>)

" vim: tabstop=2:shiftwidth=2:expandtab
