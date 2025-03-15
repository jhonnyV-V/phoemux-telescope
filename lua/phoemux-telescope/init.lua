local has_telescope, telescope = pcall(require, 'telescope')

if not has_telescope then
	error('This plugins requires nvim-telescope/telescope.nvim')
end

-- telescope modules
local actions = require("telescope.actions")
local actions_state = require("telescope.actions.state")
local pickers = require("telescope.pickers")
local themes = require "telescope.themes"
local finders = require("telescope.finders")
local conf = require("telescope.config").values

local SWITCH = "switch-session"
local KILL_AND_SWITCH = "SWITCH_AND_KILL"
local KILL_AND_TARGET = "SWITCH_AND_TARGET"

---@param str string
---@return Array<string>
local function split(str)
	local lines = {}
	local current_line = ""

	for i = 1, #str do
		local char = str:sub(i, i)
		if char == "\n" then
			table.insert(lines, current_line)
			current_line = ""
		elseif char == "\r" then
			-- handle windows style line endings, skip the \r if \n follows
			if str:sub(i + 1, i + 1) ~= "\n" then
				table.insert(lines, current_line)
				current_line = ""
			end
		else
			current_line = current_line .. char
		end
	end

	-- Add the last line if it's not empty
	if #current_line > 0 then
		table.insert(lines, current_line)
	end

	return lines
end

local function get_sessions()
	---@type Array<string>
	local sessions = {}
	local handle = io.popen("tmux list-sessions -F \"#{session_name}\"")
	if handle == nil then
		return
	end
	---@type string
	local result = handle:read("*a")
	handle:close()
	sessions = split(result)
	return sessions

end

---@param prompt_bufnr number
---@param action string
local open = function(prompt_bufnr, action)
	local command = ""
	if action == SWITCH then
		command = "tmux switch-client -t"
	elseif action == KILL_AND_SWITCH then
		command = "phoemux kill -a"
	elseif action == KILL_AND_TARGET then
		command = "phoemux kill -t"
	else
		command = "phoemux"
	end

	return function()
		actions.close(prompt_bufnr)
		local selection = actions_state.get_selected_entry()
		local v = ""

		if action == SWITCH then
			v = "\"" .. selection.value .. "\""
		else
			v = selection.value
		end
		os.execute(command .. " " .. v)
	end
end


local function ash_finder(opts)
	opts = opts or {}
	opts.cwd = opts.cwd or vim.fs.normalize(vim.fn.stdpath('config') .. "/../phoemux")
	local results = {}
	-- local command = "ls " .. opts.cwd .. " -1 -I cache | cut -d . -f1"
	-- vim.fs.dir(opts.cwd)

	for name, type in vim.fs.dir(opts.cwd) do
		if type == "file" and name ~= "cache" then
			local cleanName = string.gsub(name, ".yaml", "")
			table.insert(results, cleanName)
		end
	end

	return finders.new_table({
		results = results,
		cwd = opts.cwd,
		entry_maker = function(result)
			return {
				value = result,
				display = result,
				ordinal = result,
			}
		end
	})
end

local function session_finder(opts)
	local results = get_sessions()

	return finders.new_table({
		results = results,
		cwd = opts.cwd,
		---@param result string
		entry_maker = function(result)
			return {
				value = result,
				display = result:gsub("%s+", ""),
				ordinal = result,
			}
		end
	})
end


---@class Phoemux
---@field phoemux function
---@field switch_tmux_session function
---@field kill_and_switch_session function
---@field kill_session function
---@field kill_current_session function
local M = {}

-- Variables that setup can change
-- sort function
local cwd
local theme_opts = {}

M.setup = function(opts)
	if opts.theme and opts.theme ~= "" then
		theme_opts = themes["get_" .. opts.theme]()
	end
	if opts.cwd then
		cwd = opts.cwd
	end
end

-- This creates a picker with a list of all of the projects
M.phoemux = function(opts)
	opts = vim.tbl_deep_extend("force", theme_opts, opts or {})
	if cwd then
		opts.cwd = cwd
	end

	pickers.new(opts, {
		prompt_title = 'Find Phoemux Ash',
		finder = ash_finder(opts),
		sorter = conf.generic_sorter(opts),
		attach_mappings = function(prompt_bufnr, map)
			actions.select_default:replace(open(prompt_bufnr, ""))

			map('n', '<c-o>', open(prompt_bufnr, ""))
			map('i', '<c-o>', open(prompt_bufnr, ""))
			return true
		end
	}):find()
end

telescope.register_extension {
	exports = { phoemux = M.phoemux }
}

M.switch_tmux_session = function(opts)
	opts = vim.tbl_deep_extend("force", theme_opts, opts or {})
	if cwd then
		opts.cwd = cwd
	end

	pickers.new(opts, {
		prompt_title = 'Find Tmux Session',
		finder = session_finder(opts),
		sorter = conf.generic_sorter(opts),
		attach_mappings = function(prompt_bufnr, map)
			actions.select_default:replace(open(prompt_bufnr, SWITCH))

			map('n', '<c-o>', open(prompt_bufnr, SWITCH))
			map('i', '<c-o>', open(prompt_bufnr, SWITCH))
			return true
		end
	}):find()
end

M.kill_and_switch_session = function(opts)
	opts = vim.tbl_deep_extend("force", theme_opts, opts or {})
	if cwd then
		opts.cwd = cwd
	end

	pickers.new(opts, {
		prompt_title = 'Kill And Switch Tmux Session',
		finder = session_finder(opts),
		sorter = conf.generic_sorter(opts),
		attach_mappings = function(prompt_bufnr, map)
			actions.select_default:replace(open(prompt_bufnr, KILL_AND_SWITCH))

			map('n', '<c-o>', open(prompt_bufnr, KILL_AND_SWITCH))
			map('i', '<c-o>', open(prompt_bufnr, KILL_AND_SWITCH))
			return true
		end
	}):find()
end

M.kill_session = function(opts)
	opts = vim.tbl_deep_extend("force", theme_opts, opts or {})
	if cwd then
		opts.cwd = cwd
	end

	pickers.new(opts, {
		prompt_title = 'Kill And Switch Tmux Session',
		finder = session_finder(opts),
		sorter = conf.generic_sorter(opts),
		attach_mappings = function(prompt_bufnr, map)
			actions.select_default:replace(open(prompt_bufnr, KILL_AND_TARGET))

			map('n', '<c-o>', open(prompt_bufnr, KILL_AND_TARGET))
			map('i', '<c-o>', open(prompt_bufnr, KILL_AND_TARGET))
			return true
		end
	}):find()
end

M.kill_current_session = function()
	os.execute("phoemux kill")
end


return M
