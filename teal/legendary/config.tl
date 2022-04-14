require('legendary.types')
local M: LegendaryConfig = {
  include_builtin = true,
  include_legendary_cmds = true,
  select_prompt = function(kind: string): string
    if kind == 'legendary.items' then
      return 'Legendary'
    end

    -- Convert kind to Title Case (e.g. legendary.keymaps => Legendary Keymaps)
    return string.gsub(' ' .. kind:gsub('%.', ' '), '%W%l', string.upper):sub(2)
  end,
  formatter = nil,
  most_recent_item_at_top = true,
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

local function default_bool(value: boolean | nil, default: boolean): boolean
  if value == nil then
    return default
  end
  return value
end

---Set user configuration
---@param new_config LegendaryConfig
function M.setup(new_config: table): LegendaryConfig
  new_config = new_config or {}
  if type(new_config) ~= 'table' then
    require('legendary.utils').notify(
      string.format("require('legendary').setup() expects a table, got: %s", type(new_config))
    )
    return
  end

  M.include_builtin = default_bool(new_config.include_builtin as boolean | nil, M.include_builtin)
  M.include_legendary_cmds = default_bool(new_config.include_legendary_cmds as boolean | nil, M.include_legendary_cmds)
  M.select_prompt = (new_config.select_prompt or M.select_prompt) as (string | function(kind: string): string)
  M.formatter = (new_config.formatter or M.formatter) as function(item: LegendaryItem): {string}
  M.most_recent_item_at_top = default_bool(new_config.most_recent_item_at_top as boolean | nil, M.most_recent_item_at_top)
  M.keymaps = (new_config.keymaps or M.keymaps) as {LegendaryKeymap}
  M.commands = (new_config.commands or M.commands) as {LegendaryCommand}
  M.autocmds = (new_config.autocmds or M.autocmds) as {LegendaryAugroup}
  M.which_key = (new_config.which_key and (new_config.which_key as table).mappings and new_config.which_key or M.which_key) as LegendaryWhichKeys
  M.auto_register_which_key = default_bool(new_config.auto_register_which_key as boolean | nil, M.auto_register_which_key)
  M.scratchpad = (new_config.scratchpad or M.scratchpad) as LegendaryScratchpadConfig
  require('legendary.types').validate_config(M)
  return M
end

return M
