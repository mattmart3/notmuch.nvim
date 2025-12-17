local s = {}

local config = require("notmuch.config")

local function safe_buf_set_option(buf, name, value)
	if vim.api.nvim_buf_is_valid(buf) then
		vim.bo[buf][name] = value
	end
end

local function safe_buf_set_lines(buf, start, end_, strict, lines)
	if vim.api.nvim_buf_is_valid(buf) then
		vim.api.nvim_buf_set_lines(buf, start, end_, strict, lines)
	end
end

s.sync_maildir = function()
	local sync_cmd = config.options.maildir_sync_cmd .. " ; notmuch new"
	vim.notify("Syncing and reindexing your Maildir...", vim.log.levels.INFO)

	vim.cmd("new")
	vim.cmd("resize 10")
	local buf = vim.api.nvim_get_current_buf()
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "hide"
	vim.bo[buf].swapfile = false
	vim.bo[buf].modifiable = true
	local function random_id()
		return tostring(math.random(100000, 999999))
	end
	vim.api.nvim_buf_set_name(buf, "Notmuch sync " .. random_id())

	local output = {}

	vim.fn.jobstart(sync_cmd, {
		on_stdout = function(_, data)
			if data then
				if data[#data] == "" then
					table.remove(data, #data)
				end
				for _, line in ipairs(data) do
					table.insert(output, line)
				end
				safe_buf_set_option(buf, "modifiable", true)
				safe_buf_set_lines(buf, -1, -1, false, data)
				safe_buf_set_option(buf, "modifiable", false)
			end
		end,
		on_stderr = function(_, data)
			if data and #data > 0 then
				safe_buf_set_option(buf, "modifiable", true)
				safe_buf_set_lines(buf, -1, -1, false, data)
				safe_buf_set_option(buf, "modifiable", false)
			end
		end,
		on_exit = function(_, code)
			safe_buf_set_option(buf, "modifiable", true)
			if code == 0 then
				safe_buf_set_lines(buf, -1, -1, false, { "", "Maildir sync finished successfully!" })
			else
				safe_buf_set_lines(buf, -1, -1, false, { "", "Maildir sync failed!" })
			end
			safe_buf_set_option(buf, "modifiable", false)
		end,
		stdout_buffered = false,
		stderr_buffered = false,
	})
end

return s

-- vim: tabstop=2:shiftwidth=2:expandtab:foldmethod=indent
