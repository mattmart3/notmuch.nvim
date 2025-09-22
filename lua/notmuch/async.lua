local a = {}

-- Runs `notmuch search` asynchronously
--
-- This function leverages the `vim.loop` library to spawn a subprocess and
-- asynchronously run the `notmuch` search query in the background so it does
-- not block `nvim`s event loop and allow seamless UX while results flow in
--
-- @param search string: search term to query. see `notmuch-search-terms(7)`
-- @param buf int: refers to the buffer id to write the output to
-- @param on_complete func: callback function to execute once process completes
--
-- @usage
-- -- Refer to `init.lua` for example invocation
-- require('notmuch.async').run_notmuch_search('tag:inbox', 0, function()
--   print('Notmuch search process completed.')
-- end)
a.run_notmuch_search = function(search, buf, on_complete)
  -- Set up pipes for stdout and stderr to capture command output
  local stdout = vim.loop.new_pipe(false)
  local stderr = vim.loop.new_pipe(false)

  -- Helper variable for maintaining incomplete lines between reads
  local partial_data = ""

  -- Spawn subprocess using vim.loop (deprecated?)
  local handle

  handle = vim.loop.spawn("notmuch", {
    args = {"search", "--format", "json", "--sort", "oldest-first", search},
    stdio = {nil, stdout, stderr}
  }, vim.schedule_wrap(function()
    -- XXX: This loads everything at the end.
    -- TODO: It should be handled with multiple notmuch searches with fixed limit and progressive offset.
    local ok, json_tbl = pcall(vim.json.decode, partial_data)
    if not ok or type(json_tbl) ~= 'table' then
      vim.notify(('ERROR: Failed to decode json: %s'):format(json_tbl or 'unknown error'))
    else
      local lines = {}
      for i = #json_tbl, 1, -1 do -- XXX: reverse order to adjust oldest-first list
        local item = json_tbl[i]
        local line = string.format(
          "thread:%s %s [%d/%d] %s; %s (%s)",
          item.thread,
          item.date_relative,
          item.matched,
          item.total,
          #item.authors <= 30 and item.authors or string.sub(item.authors, 1, 20) .. "...",
          item.subject,
          table.concat(item.tags, " ")
        )
        table.insert(lines, line)
      end
      -- Paste lines into the tail of `buf`
      vim.bo[buf].modifiable = true
      vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
      vim.bo[buf].modifiable = false
    end

    -- Close the pipes and handle
    stdout:close()
    stderr:close()
    handle:close()

    -- Call the completion callback
    on_complete()
  end))

  -- Read data from stdout and write it to the buffer
  vim.loop.read_start(stdout, vim.schedule_wrap(function(_, data)
    if data then
      -- Combine earlier incomplete chunk with newest read
      partial_data = partial_data .. data
    end
  end))

  -- Log errors from stderr
  vim.loop.read_start(stderr, vim.schedule_wrap(function(err, _)
    if err then
      vim.notify("ERROR: " .. err)
    end
  end))
end

return a
