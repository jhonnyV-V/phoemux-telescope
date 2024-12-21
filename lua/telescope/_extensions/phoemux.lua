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

local open = function(prompt_bufnr)
	return function()
		actions.close(prompt_bufnr)
		local selection = actions_state.get_selected_entry()
		print(selection.value)
		os.execute("phoemux " .. selection.value)
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

local M = {}

-- Variables that setup can change
-- sort function
local cwd
local theme_opts = {}

M.setup = function(setup_config)
	if setup_config.theme and setup_config.theme ~= "" then
		theme_opts = themes["get_" .. setup_config.theme]()
	end
	if setup_config.cwd then
		cwd = setup_config.cwd
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
			actions.select_default:replace(open(prompt_bufnr))

			map('n', '<c-o>', open(prompt_bufnr))
			map('i', '<c-o>', open(prompt_bufnr))
			return true
		end
	}):find()
end

return telescope.register_extension{
  setup = M.setup,
  exports = { phoemux = M.phoemux }
}
