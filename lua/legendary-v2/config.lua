local config = {
  keymaps = {},
  commands = {},
  autocmds = {},
  functions = {},
  select_prompt = ' legendary.nvim ',
  col_separator_char = '│',
  default_item_formatter = nil,
  include_builtin = true,
  include_legendary_cmds = true,
  most_recent_items_at_top = true,
  which_key = {
    auto_register = false,
    mappings = {},
    opts = {},
    do_binding = true,
  },
  scratchpad = {
    view = 'float', -- 'current' | 'float'
    results_view = 'float', -- 'print' | 'float'
    cache_path = string.format('%s/%s', vim.fn.stdpath('cache'), 'legendary_scratch.lua'),
    float_border = 'rounded',
  },
}

---@class LegendaryWhichkeyConfig
---@field auto_register boolean
---@field mappings table[]
---@field opts table
---@field do_binding boolean

---@class LegendaryScratchpadConfig
---@field view 'float'|'current'
---@field results_view 'float'|'print'
---@field cache_path string|false
---@field float_border string

---@class LegendaryConfig
---@field keymaps Keymap[]
---@field commands Command[]
---@field autocmds (Augroup|Autocmd)[]
---@field functions Function[]
---@field select_prompt string|fun():string
---@field col_separator_char string
---@field default_item_formatter ItemFormatter
---@field include_builtin boolean
---@field include_legendary_cmds boolean
---@field most_recent_items_at_top boolean
---@field which_key LegendaryWhichkeyConfig
---@field scratchpad LegendaryScratchpadConfig
local M = setmetatable({}, {
  __index = function(_, key)
    return config[key]
  end,
  __newindex = function(_, key, value)
    config[key] = value
  end,
})

function M.setup(cfg)
  config = vim.tbl_deep_extend('force', config, cfg or {})
end

return M
