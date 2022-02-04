local M = {}

if not vim.keymap or not vim.keymap.set then
  vim.api.nvim_err_write('Sorry, legendary.nvim requires Neovim 0.7.0 or higher!')
  return
end

M.bind = require('legendary.bindings').bind
M.find = require('legendary.bindings').find

function M.setup(new_config)
  local config = require('legendary.config')
  config.setup(new_config)
  if config.include_builtin then
    require('legendary.builtins').register_builtins()
  end
end

return M
