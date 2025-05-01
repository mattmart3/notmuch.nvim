setlocal nowrap

let nm = v:lua.require('notmuch')
let r = v:lua.require('notmuch.refresh')
let s = v:lua.require('notmuch.sync')
let tag = v:lua.require('notmuch.tag')

command -buffer -range -complete=custom,notmuch#CompTags -nargs=+ TagAdd :call tag.thread_add_tag(<q-args>, <line1>, <line2>)
command -buffer -range -complete=custom,notmuch#CompTags -nargs=+ TagRm :call tag.thread_rm_tag(<q-args>, <line1>, <line2>)
command -buffer -range -complete=custom,notmuch#CompTags -nargs=+ TagToggle :call tag.thread_toggle_tag(<q-args>, <line1>, <line2>)
command -buffer -range DelThread :call tag.thread_add_tag("del", <line1>, <line2>) | :call tag.thread_rm_tag("inbox", <line1>, <line2>)

nnoremap <buffer> <silent> <CR> :call nm.show_thread()<CR>
nnoremap <buffer> <silent> r :call r.refresh_search_buffer()<CR>
nnoremap <buffer> <silent> q :bwipeout<CR>
nnoremap <buffer> <silent> % :call s.sync_maildir()<CR>
nnoremap <buffer> + :TagAdd 
xnoremap <buffer> + :TagAdd 
nnoremap <buffer> - :TagRm 
xnoremap <buffer> - :TagRm 
nnoremap <buffer> = :TagToggle 
xnoremap <buffer> = :TagToggle 
nnoremap <buffer> a :TagToggle inbox<CR>j
xnoremap <buffer> a :TagToggle inbox<CR>
nnoremap <buffer> A :TagRm inbox unread<CR>j
xnoremap <buffer> A :TagRm inbox unread<CR>
nnoremap <buffer> x :TagToggle unread<CR>
xnoremap <buffer> x :TagToggle unread<CR>
nnoremap <buffer> f :TagToggle flagged<CR>j
xnoremap <buffer> f :TagToggle flagged<CR>
nnoremap <buffer> <silent> C :call v:lua.require('notmuch.send').compose()<CR>
nnoremap <buffer> dd :DelThread<CR>j
xnoremap <buffer> d :DelThread<CR>
nnoremap <buffer> <silent> D :lua require('notmuch.delete').purge_del()<CR>
