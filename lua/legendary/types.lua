local M = {}

---@class LegendaryConfig
---@field include_builtin boolean
---@field select_prompt string | function
---@field formatter function
---@field keymaps LegendaryItem[]
---@field commands LegendaryItem[]
---@field autocmds LegendaryAugroup[] | LegendaryItem[]
---@field auto_register_which_key boolean
M.LegendaryConfig = {
  validate = function(config)
    -- diagnostics see vim.validate() as not accepting any parameters for some reason
    ---@diagnostic disable-next-line: redundant-parameter
    vim.validate({
      include_builtin = { config.include_builtin, 'boolean', true },
      select_prompt = { config.select_prompt, { 'string', 'function' }, true },
      formatter = { config.formatter, 'function', true },
      keymaps = { config.keymaps, 'table', true },
      commands = { config.keymaps, 'table', true },
      autocmds = { config.keymaps, 'table', true },
      auto_register_which_key = { config.auto_register_which_key, 'boolean', true },
    })
  end,
}

---@class LegendaryItem
---@field [1] string
---@field [2] string | function | nil
---@field mode string | string[]
---@field description string
---@field opts table
---@field kind string
---@field id number
---@field lazy nil | LegendaryLazy
M.LegendaryItem = {
  validate = function(item)
    -- diagnostics see vim.validate() as not accepting any parameters for some reason
    ---@diagnostic disable-next-line: redundant-parameter
    vim.validate({
      [1] = { item[1], { 'string', 'table' } }, -- [1] can be a table for autocmds
      [2] = { item[2], { 'string', 'function' }, true },
      mode = { item.mode, { 'string', 'table' }, true },
      description = { item.description, { 'string' }, true },
      opts = { item.opts, 'table', true },
      kind = { item.kind, 'string' },
      id = { item.id, 'number' },
    })
  end,
}

---@class LegendaryLazy
---@field event string | table
---@field pattern string | table | nil
M.LegendaryLazy = {
  validate = function(lazy)
    -- diagnostics see vim.validate() as not accepting any parameters for some reason
    ---@diagnostic disable-next-line: redundant-parameter
    vim.validate({
      lazy = { lazy, 'table' },
      lazy_event = { lazy.event, { 'string', 'table' } },
      lazy_pattern = { lazy.pattern, { 'string', 'table' }, true },
    })
  end,
}

---@class LegendaryAugroup
---@field name string
---@field clear boolean
---@field [1] LegendaryItem[]
M.LegendaryAugroup = {
  validate = function(au)
    -- the autocmds inside get validated by LegendaryItem.validate at bind time
    -- diagnostics see vim.validate() as not accepting any parameters for some reason
    ---@diagnostic disable-next-line: redundant-parameter
    vim.validate({
      name = { au.name, 'string' },
      clear = { au.clear, 'boolean', true },
    })
  end,
}

return M
