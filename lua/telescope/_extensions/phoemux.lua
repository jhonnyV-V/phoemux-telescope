local has_telescope, telescope = pcall(require, 'telescope')
local phoemux = require('telescope._extensions.phoemux.main')

if not has_telescope then
  error('This plugins requires nvim-telescope/telescope.nvim')
end

return telescope.register_extension{
  setup = phoemux.setup,
  exports = { phoemux = phoemux.phoemux }
}
