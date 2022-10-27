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
  col_separator_char = '│',
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
  auto_register_which_key = false,
  scratchpad = {
    display_results = 'float',
    cache_file = string.format('%s/%s', vim.fn.stdpath('cache'), 'legendary_scratch.lua'),
  },
  plugins = {
    diffview = false,
    smart_splits = false,
    op = false,
    onedarkpro = false,
  }
}

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

  local result = vim.tbl_deep_extend("force", M as table, new_config or {})
  for key, value in pairs(result) do
    (M as table)[key as string] = value
  end

  return M
end

return M
