---@type LegendaryConfig
local M = {
  include_builtin = true,
  select_prompt = 'Legendary',
  keymaps = {},
  commands = {},
  autocmds = {},
  auto_register_which_key = true,
}

local function default_bool(value, default)
  if value == nil then
    return default
  end
  return value
end

---Set user configuration
---@param new_config LegendaryConfig
function M.setup(new_config)
  new_config = new_config or {}
  if type(new_config) ~= 'table' then
    require('legendary.util').notify(
      string.format("require('legendary').setup() expects a table, got: %s", type(new_config))
    )
    return
  end

  M.include_builtin = default_bool(new_config.include_builtin, M.include_builtin)
  M.select_prompt = new_config.select_prompt or M.select_prompt
  M.keymaps = new_config.keymaps or M.keymaps
  M.commands = new_config.commands or M.commands
  M.autocmds = new_config.autocmds or M.autocmds
  M.auto_register_which_key = default_bool(new_config.auto_register_which_key, M.auto_register_which_key)
end

return M
