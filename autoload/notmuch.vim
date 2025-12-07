let s:search_terms_list = [ "attachment:", "folder:", "id:", "mimetype:",
      \ "property:", "subject:", "thread:", "date:", "from:", "lastmod:",
      \ "path:", "query:", "tag:", "is:", "to:", "body:", "and ", "or ", "not " ]

function! notmuch#CompSearchTerms(ArgLead, CmdLine, CursorPos) abort
  if match(a:ArgLead, "tag:") != -1
    let l:tag_list = split(system('notmuch search --output=tags "*"'), '\n')
    return "tag:" .. join(l:tag_list, "\ntag:")
  endif
  if match(a:ArgLead, "is:") != -1
    let l:is_list = split(system('notmuch search --output=tags "*"'), '\n')
    return "is:" .. join(l:is_list, "\nis:")
  endif
  if match(a:ArgLead, "mimetype:") != -1
    let l:mimetype_list = ["application/", "audio/", "chemical/",
          \ "font/", "image/", "inode/", "message/", "model/",
          \ "multipart/", "text/", "video/"]
    return "mimetype:" .. join(l:mimetype_list, "\nmimetype:")
  endif
  if match(a:ArgLead, "from:") != -1
    let l:from_list = split(system('notmuch address "*"'), '\n')
    return "from:" .. join(l:from_list, "\nfrom:")
  endif
  if match(a:ArgLead, "to:") != -1
    let l:to_list = split(system('notmuch address "*"'), '\n')
    return "to:" .. join(l:to_list, "\nto:")
  endif
  if match(a:ArgLead, "folder:") != -1
    let l:cur_dirs = split(system('find ' .. shellescape(g:notmuch_mailroot) .. ' -type d -name cur'), '\n')
    let folder_list = []
    let l:mailroot_pattern = '^' .. escape(g:notmuch_mailroot, '/.\\$*[]^') .. '/\?'
    for dir in l:cur_dirs
      let l:parent = fnamemodify(dir, ':h')
      let l:relative = substitute(l:parent, l:mailroot_pattern, '', '')
      if !empty(l:relative)
        " Quote folder names that contain spaces or special characters
        if match(l:relative, '[ \[\]]') != -1
          let l:relative = '"' .. l:relative .. '"'
        endif
        call add(l:folder_list, l:relative)
      endif
    endfor
    return "folder:" .. join(uniq(sort(l:folder_list)), "\nfolder:")
  endif
  if match(a:ArgLead, "path:") != -1
    let l:all_dirs = split(system('find ' .. shellescape(g:notmuch_mailroot) .. ' -type d'), '\n')
    let l:path_list = []
    let l:mailroot_pattern = '^' .. escape(g:notmuch_mailroot, '/.\\$*[]^') .. '/\?'
    for dir in l:all_dirs
      let l:relative = substitute(dir, l:mailroot_pattern, '', '')
      if !empty(l:relative)
        " Quote paths that contain spaces or special characters
        if match(l:relative, '[ \[\]]') != -1
          let l:relative = '"' .. l:relative .. '"'
        endif
        call add(l:path_list, l:relative)
      endif
    endfor
    return "path:" .. join(uniq(sort(l:path_list)), "\npath:")
  endif
  return join(s:search_terms_list, "\n")
endfunction

function! notmuch#CompTags(ArgLead, CmdLine, CursorPos) abort
  return system('notmuch search --output=tags "*"')
endfunction

function! notmuch#CompAddress(ArgLead, CmdLine, CursorPos) abort
  return system('notmuch address "*"')
endfunction
" vim: tabstop=2:shiftwidth=2:expandtab
