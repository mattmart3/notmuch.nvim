local v = vim.api
local u = {}

-- 99% sure there is a better way to do this !!!
u.print_table = function(tab)
  for k,v in pairs(tab) do
    print(v)
  end
end

u.capture = function(cmd)
  local f = assert(io.popen(cmd, 'r'))
  local out = assert(f:read('*a')) -- *a means all content of pipe/file
  f:close()
  return out
end

-- there is a better way to do this !!!
u.split = function(s, delim)
  local out = {}
  local i = 1
  for entry in string.gmatch(s, delim) do
    out[i] = entry
    i = i + 1
  end
  return out
end

u.find_cursor_msg_id = function()
  local n = v.nvim_win_get_cursor(0)[1] + 1
  local line = nil
  local id = nil
  while n ~= 1 do
    line = vim.fn.getline(n)
    if string.match(line, '^id:%S+ {{{$') ~= nil then
      id = string.match(line, '%S+', 4)
      return id
    end
    n = n - 1
  end
  return nil
end

return u

-- vim: tabstop=2:shiftwidth=2:expandtab:foldmethod=indent
