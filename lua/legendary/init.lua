local M = {}

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
