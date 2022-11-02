local config = {
  keymaps = {},
  commands = {},
  autocmds = {},
  functions = {},
  select_prompt = ' legendary.nvim ',
  col_separator_char = '│',
  default_item_formatter = nil,
}

---@class LegendaryConfig
---@field keymaps Keymap[]
---@field commands Command[]
---@field autocmds (Augroup|Autocmd)[]
---@field functions Function[]
---@field select_prompt string|fun():string
---@field col_separator_char string
---@field default_item_formatter ItemFormatter
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
