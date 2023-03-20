local Log = require('legendary.log')

local M = {}

function M.load_all(extensions)
  if type(extensions) ~= 'table' then
    Log.error('config.extensions must be a table; received %s', type(extensions))
    return
  end

  for extension_name, extension_config in pairs(extensions) do
    local load_status, module_or_error = pcall(require, string.format('legendary.extensions.%s', extension_name))
    if not load_status then
      Log.error('Error loading extensions %q: %s', vim.inspect(module_or_error))
    else
      local module = module_or_error -- now known to not be an error
      if type(module) ~= 'function' then
        Log.error('Extension %q does not return a function.', extension_name)
      else
        -- module is a function
        local ok, error = pcall(module, extension_config)
        if not ok then
          Log.error('Extension %q failed to initialize: %s', vim.inspect(error))
        end
      end
    end
  end
end

return M
