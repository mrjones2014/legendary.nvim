---@type LegendaryConfig
local M = {
  include_builtin = true,
  include_legendary_cmds = true,
  select_prompt = function(kind)
    if kind == 'legendary.items' then
      return 'Legendary'
    end

    -- Convert kind to Title Case (e.g. legendary.keymaps => Legendary Keymaps)
    return string.gsub(' ' .. kind:gsub('%.', ' '), '%W%l', string.upper):sub(2)
  end,
  formatter = nil,
  most_recent_item_at_top = true,
  restore_visual_after_exec = true,
  keymaps = {},
  commands = {},
  autocmds = {},
  which_key = {
    mappings = {},
    opts = {},
  },
  auto_register_which_key = true,
  scratchpad = {
    display_results = 'float',
  },
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
    require('legendary.utils').notify(
      string.format("require('legendary').setup() expects a table, got: %s", type(new_config))
    )
    return
  end

  M.include_builtin = default_bool(new_config.include_builtin, M.include_builtin)
  M.select_prompt = new_config.select_prompt or M.select_prompt
  M.formatter = new_config.formatter or M.formatter
  M.most_recent_item_at_top = default_bool(new_config.most_recent_item_at_top, M.most_recent_item_at_top)
  M.restore_visual_after_exec = default_bool(new_config.restore_visual_after_exec, M.restore_visual_after_exec)
  M.keymaps = new_config.keymaps or M.keymaps
  M.commands = new_config.commands or M.commands
  M.autocmds = new_config.autocmds or M.autocmds
  M.which_key = new_config.which_key and new_config.which_key.mappings and new_config.which_key or M.which_key
  M.auto_register_which_key = default_bool(new_config.auto_register_which_key, M.auto_register_which_key)
  M.scratchpad = new_config.scratchpad or M.scratchpad
  require('legendary.types').LegendaryConfig.validate(M)
end

return M
