local config = {
  -- Initial keymaps to bind
  keymaps = {},
  -- Initial commands to bind
  commands = {},
  -- Initial augroups/autocmds to bind
  autocmds = {},
  -- Initial functions to bind
  functions = {},
  -- default opts to merge with the `opts` table
  -- of each individual item
  default_opts = {
    keymaps = {},
    commands = {},
    autocmds = {},
  },
  -- Customize the prompt that appears on your vim.ui.select() handler
  -- Can be a string or a function that returns a string.
  select_prompt = ' legendary.nvim ',
  -- Character to use to separate columns in the UI
  col_separator_char = '│',
  -- Optionally pass a custom formatter function. This function
  -- receives the item as a parameter and the mode that legendary
  -- was triggered from (e.g. `function(item, mode): string[]`)
  -- and must return a table of non-nil string values for display.
  -- It must return the same number of values for each item to work correctly.
  -- The values will be used as column values when formatted.
  -- See function `default_format(item)` in
  -- `lua/legendary/ui/format.lua` to see default implementation.
  default_item_formatter = nil,
  -- Include builtins by default, set to false to disable
  include_builtin = true,
  -- Include the commands that legendary.nvim creates itself
  -- in the legend by default, set to false to disable
  include_legendary_cmds = true,
  -- Sort most recently used items to the top of the list
  -- so they can be quickly re-triggered when opening legendary again
  most_recent_items_at_top = true,
  which_key = {
    -- Automatically add which-key tables to legendary
    -- see ./doc/WHICH_KEY.md for more details
    auto_register = false,
    -- you can put which-key.nvim tables here,
    -- or alternatively have them auto-register,
    -- see ./doc/WHICH_KEY.md
    mappings = {},
    opts = {},
    -- controls whether legendary.nvim actually binds they keymaps,
    -- or if you want to let which-key.nvim handle the bindings.
    -- if not passed, true by default
    do_binding = true,
  },
  scratchpad = {
    -- How to open the scratchpad buffer,
    -- 'current' for current window, 'float'
    -- for floating window
    view = 'float',
    -- How to show the results of evaluated Lua code.
    -- 'print' for `print(result)`, 'float' for a floating window.
    results_view = 'float',
    -- Border style for floating windows related to the scratchpad
    float_border = 'rounded',
    -- Whether to restore scratchpad contents from a cache file
    keep_contents = true,
  },
  -- Directory used for caches
  cache_path = string.format('%s/legendary/', vim.fn.stdpath('cache')),
}

---@class LegendaryWhichkeyConfig
---@field auto_register boolean
---@field mappings table[]
---@field opts table
---@field do_binding boolean

---@class LegendaryScratchpadConfig
---@field view 'float'|'current'
---@field results_view 'float'|'print'
---@field float_border string
---@field keep_contents boolean

---@class LegendaryDefaultOptsConfig
---@field keymaps table
---@field commands table
---@field autocmds table
---@field functions table

---@class LegendaryConfig
---@field keymaps Keymap[]
---@field commands Command[]
---@field autocmds (Augroup|Autocmd)[]
---@field functions Function[]
---@field default_opts LegendaryDefaultOptsConfig
---@field select_prompt string|fun():string
---@field col_separator_char string
---@field default_item_formatter LegendaryItemFormatter
---@field include_builtin boolean
---@field include_legendary_cmds boolean
---@field most_recent_items_at_top boolean
---@field which_key LegendaryWhichkeyConfig
---@field scratchpad LegendaryScratchpadConfig
---@field cache_path string
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
  config = require('legendary.deprecate').check_config(config)
end

return M
