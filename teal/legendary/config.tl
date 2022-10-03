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
  functions = {},
  which_key = {
    mappings = {},
    opts = {},
    do_binding = true,
  },
  auto_register_which_key = true,
  scratchpad = {
    display_results = 'float',
    cache_file = string.format('%s/%s', vim.fn.stdpath('cache'), 'legendary_scratch.lua'),
  },
}

local function default_bool(value: boolean | nil, default: boolean): boolean
  if value == nil then
    return default
  end
  return value
end

local function default_whichkey(new_config: table): LegendaryWhichKeys
  if not new_config then
    return M.which_key
  end

  return {
    mappings = new_config.mappings or {},
    opts = new_config.opts or {},
    do_binding = default_bool(new_config.do_binding as boolean | nil, true)
  }
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
  M.functions = (new_config.functions or M.functions) as {LegendaryFunction}
  M.which_key = default_whichkey(new_config.which_key as table)
  M.auto_register_which_key = default_bool(new_config.auto_register_which_key as boolean | nil, M.auto_register_which_key)
  M.scratchpad = vim.tbl_deep_extend('force', M.scratchpad as table, (new_config.scratchpad or {}) as table) as LegendaryScratchpadConfig
  require('legendary.types').validate_config(M)
  return M
end

return M
