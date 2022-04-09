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
---@field [2] string | function | table | nil
---@field mode string | string[]
---@field description string
---@field opts table
---@field kind string
---@field id number
M.LegendaryItem = {
  validate = function(item)
    -- diagnostics see vim.validate() as not accepting any parameters for some reason
    ---@diagnostic disable-next-line: redundant-parameter
    vim.validate({
      [1] = { item[1], { 'string', 'table' } }, -- [1] can be a table for autocmds
      [2] = { item[2], { 'string', 'function', 'table' }, true },
      mode = { item.mode, { 'string', 'table' }, true },
      description = { item.description, { 'string' }, true },
      opts = { item.opts, 'table', true },
      kind = { item.kind, 'string' },
      id = { item.id, 'number' },
    })

    if item and type(item[2]) == 'table' and item.mode ~= nil then
      require('legendary.utils').notify(
        'Second mapping table element is a table for per-mode mappings, mode property will be ignored. '
          .. vim.inspect(item),
        vim.log.levels.WARN
      )
    end
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
