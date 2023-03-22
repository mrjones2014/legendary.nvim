local Log = require('legendary.log')

local M = {}

---Load all extensions specified in legendary.nvim config
function M.load_all()
  local extensions = require('legendary.config').extensions
  if type(extensions) ~= 'table' then
    Log.error('config.extensions must be a table; received %s', type(extensions))
    return
  end

  for extension_name, extension_config in pairs(extensions) do
    M.load_extension(extension_name, extension_config)
  end
end

---Load a single extension by name. If config is not provided,
---it will be looked up in the legendary.nvim config.
---@param extension_name string
---@param config any
function M.load_extension(extension_name, config)
  local extension_config = config
  if extension_config == nil then
    extension_config = require('legendary.config').extensions[extension_name]
  end

  if extension_config == false then
    return
  end

  local load_status, module_or_error = pcall(require, string.format('legendary.extensions.%s', extension_name))
  if not load_status then
    Log.error('Error loading extensions %q: %s', extension_name, vim.inspect(module_or_error))
  else
    local module = module_or_error -- now known to not be an error
    if type(module) ~= 'function' then
      Log.error('Extension %q does not return a function.', extension_name)
    else
      -- module is a function
      local ok, error = pcall(module, extension_config)
      if not ok then
        Log.error('Extension %q failed to initialize: %s', extension_name, vim.inspect(error))
      end
    end
  end
end

return M
