local config = {
  keymaps = {},
  commands = {},
  autocmds = {},
  functions = {},
  select_prompt = ' legendary.nvim ',
  col_separator_char = '│',
  default_item_formatter = nil,
  include_builtin = true,
  most_recent_items_at_top = true,
  which_key = {
    auto_register = false,
    mappings = {},
    opts = {},
    do_binding = true,
  },
}

---@class LegendaryWhichkeyConfig
---@field auto_register boolean
---@field mappings table[]
---@field opts table
---@field do_binding boolean

---@class LegendaryConfig
---@field keymaps Keymap[]
---@field commands Command[]
---@field autocmds (Augroup|Autocmd)[]
---@field functions Function[]
---@field select_prompt string|fun():string
---@field col_separator_char string
---@field default_item_formatter ItemFormatter
---@field include_builtin boolean
---@field most_recent_items_at_top boolean
---@field which_key LegendaryWhichkeyConfig
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
