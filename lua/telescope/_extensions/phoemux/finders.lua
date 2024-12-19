local finders = require("telescope.finders")

local M = {}

-- Creates a Telescope `finder` based on the given options
-- and list of projects
M.ash_finder = function(opts)
	opts = opts or {}
	opts.cwd = opts.cwd or os.execute("realpath " .. vim.fn.stdpath('config') .. "/../phoemux")

	return finders.new_async_job({
		command_generator = function (prompt)
			local args = {
				"ls",
				opts.cwd,
				"-1",
				"-I",
				"cache",
				"|",
				"grep",
				prompt,
				"|",
				"cut",
				"-d",
				".",
				"-f1"
			}
			return args
		end,
		cwd = opts.cwd,
		entry_maker = function (result)
			return {
				value = result,
				display = result,
				ordinal = result,
			}
		end
	})
end

return M
