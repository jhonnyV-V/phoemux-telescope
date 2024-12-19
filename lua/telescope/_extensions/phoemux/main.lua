local has_telescope = pcall(require, "telescope")
if not has_telescope then
  error("This plugins requires nvim-telescope/telescope.nvim")
end
-- telescope modules
local actions = require("telescope.actions")
local pickers = require("telescope.pickers")
local themes = require "telescope.themes"

local phoemux_pickers = require("telescope._extensions.project.finders")

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
    finder = phoemux_pickers.ash_finder(opts),
    sorter = require("telescope.sorters").empty(),
    attach_mappings = function(prompt_bufnr)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = actions.state.get_selected_entry()
        print(vim.inspect(selection))
        os.execute("phoemux " .. selection)
      end)
      return true
    end
  }):find()
end

M.phoemux()

return M
