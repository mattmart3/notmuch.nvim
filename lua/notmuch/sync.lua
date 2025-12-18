local s = {}

local config = require("notmuch.config")
local current_sync_job = nil

-- Public job management functions
s.create_job = function(cmd, opts)
	opts = opts or {}
	local job_id = vim.fn.jobstart(cmd, {
		on_stdout = opts.on_stdout,
		on_stderr = opts.on_stderr,
		on_exit = opts.on_exit,
		stdout_buffered = opts.stdout_buffered or false,
		stderr_buffered = opts.stderr_buffered or false,
	})
	return job_id
end

s.stop_job = function(job_id)
	if job_id then
		vim.fn.jobstop(job_id)
		return true
	end
	return false
end

s.is_job_running = function(job_id)
	return job_id and vim.fn.jobwait({job_id}, 0)[1] == -1
end

s.get_current_sync_job = function()
	return current_sync_job
end

s.set_current_sync_job = function(job_id)
	current_sync_job = job_id
end

-- UI-specific functions
local ui = {}

ui.safe_buf_set_option = function(buf, name, value)
	if vim.api.nvim_buf_is_valid(buf) then
		vim.bo[buf][name] = value
	end
end

ui.safe_buf_set_lines = function(buf, start, end_, strict, lines)
	if vim.api.nvim_buf_is_valid(buf) then
		vim.api.nvim_buf_set_lines(buf, start, end_, strict, lines)
	end
end

ui.find_buffer_by_name = function(pattern)
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		local name = vim.api.nvim_buf_get_name(buf)
		if name:match(pattern) then
			return buf
		end
	end
	return nil
end

ui.find_sync_buffer = function()
	return ui.find_buffer_by_name("notmuch%-sync$")
end

ui.clear_buffer = function(buf)
	if vim.api.nvim_buf_is_valid(buf) then
		ui.safe_buf_set_option(buf, "modifiable", true)
		vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
		ui.safe_buf_set_option(buf, "modifiable", false)
	end
end

ui.setup_cancel_keymap = function(buf, job_id, opts)
	opts = opts or {}
	vim.keymap.set('n', '<C-c>', function()
		if s.stop_job(job_id) then
			if vim.api.nvim_buf_is_valid(buf) then
				ui.safe_buf_set_option(buf, "modifiable", true)
				ui.safe_buf_set_lines(buf, -1, -1, false, {"", opts.cancel_msg or "Job cancelled!"})
				ui.safe_buf_set_option(buf, "modifiable", false)
			end
		end
	end, { buffer = buf, desc = opts.desc or "Cancel job" })
end

ui.switch_to_buffer = function(buf)
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_get_buf(win) == buf then
			vim.api.nvim_set_current_win(win)
			return true
		end
	end
	if vim.api.nvim_get_current_buf() ~= buf then
		vim.api.nvim_set_current_buf(buf)
		return true
	end
	return false
end

ui.create_sync_buffer = function()
	vim.cmd("new")
	vim.cmd("resize 10")
	local buf = vim.api.nvim_get_current_buf()
	vim.bo[buf].buftype = "nofile"
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].swapfile = false
	vim.bo[buf].modifiable = true
	vim.api.nvim_buf_set_name(buf, "notmuch-sync")
	return buf
end

-- Export UI functions for other modules
s.ui = ui

s.sync_maildir = function()
	-- Check if sync is already running
	if current_sync_job then
		local buf = ui.find_sync_buffer()
		if buf then
			ui.switch_to_buffer(buf)
			vim.notify("Sync is already running. Showing existing sync buffer.", vim.log.levels.WARN)
		else
			vim.notify("Sync is already running but no buffer found.", vim.log.levels.WARN)
		end
		return
	end

	local sync_cmd = config.options.maildir_sync_cmd .. " ; notmuch new"
	local sync_mode = config.options.sync and config.options.sync.sync_mode or "buffer"

	if sync_mode == "background" then
		vim.notify("Syncing and reindexing your Maildir in background...", vim.log.levels.INFO)
		current_sync_job = s.create_job(sync_cmd, {
			on_exit = function(_, code)
				current_sync_job = nil
				if code == 0 then
					vim.notify("Maildir sync finished successfully!", vim.log.levels.INFO)
				else
					vim.notify("Maildir sync failed!", vim.log.levels.ERROR)
				end
			end,
		})
		return
	end

	vim.notify("Syncing and reindexing your Maildir...", vim.log.levels.INFO)

	local buf = ui.find_sync_buffer()
	if buf then
		ui.switch_to_buffer(buf)
		ui.clear_buffer(buf)
	else
		buf = ui.create_sync_buffer()
	end

	local output = {}

	local job_id = s.create_job(sync_cmd, {
		on_stdout = function(_, data)
			if data then
				if data[#data] == "" then
					table.remove(data, #data)
				end
				for _, line in ipairs(data) do
					table.insert(output, line)
				end
				ui.safe_buf_set_option(buf, "modifiable", true)
				ui.safe_buf_set_lines(buf, -1, -1, false, data)
				ui.safe_buf_set_option(buf, "modifiable", false)
			end
		end,
		on_stderr = function(_, data)
			if data and #data > 0 then
				ui.safe_buf_set_option(buf, "modifiable", true)
				ui.safe_buf_set_lines(buf, -1, -1, false, data)
				ui.safe_buf_set_option(buf, "modifiable", false)
			end
		end,
		on_exit = function(_, code)
			current_sync_job = nil
			ui.safe_buf_set_option(buf, "modifiable", true)
			if code == 0 then
				ui.safe_buf_set_lines(buf, -1, -1, false, { "", "Maildir sync finished successfully!" })
			else
				ui.safe_buf_set_lines(buf, -1, -1, false, { "", "Maildir sync failed!" })
			end
			ui.safe_buf_set_option(buf, "modifiable", false)
		end,
		stdout_buffered = false,
		stderr_buffered = false,
	})
	current_sync_job = job_id

	ui.setup_cancel_keymap(buf, job_id, {cancel_msg = "Sync job cancelled!"})
end

return s

-- vim: tabstop=2:shiftwidth=2:expandtab:foldmethod=indent
