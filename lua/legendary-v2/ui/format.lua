local Config = require('legendary-v2.config')
local Toolbox = require('legendary-v2.toolbox')

local M = {}

local function rpad(str, len)
  return string.format('%s%s', str, string.rep(' ', len - (vim.fn.strdisplaywidth(str))))
end

---@alias ItemFormatter fun(items:LegendaryItem[],mode:string):string[]

---Default format
---@param item LegendaryItem
---@return string[]
function M.default_format(item)
  if Toolbox.is_keymap(item) then
    return {
      table.concat(item:modes(), ', '),
      item.keys,
      item.description,
    }
  elseif Toolbox.is_command(item) then
    return {
      '',
      item.cmd,
      item.description,
    }
  elseif Toolbox.is_autocmd(item) then
    return {
      table.concat(item.events, ', '),
      table.concat(vim.tbl_get(item, 'opts', 'pattern') or { '*' }, ', '),
      item.description,
    }
  elseif Toolbox.is_function(item) then
    return {
      '',
      '<function>',
      item.description,
    }
  else
    -- unreachable
    return {
      vim.inspect(item),
      '',
      '',
    }
  end
end

---Format items
---@param items LegendaryItem[]
---@param mode string
---@param formatter ItemFormatter
function M.compute_padding(items, formatter, mode)
  formatter = formatter or M.default_format
  local format_values = vim.tbl_map(function(item)
    return formatter(item, mode)
  end, items)

  local padding = {}
  for _, cols in ipairs(format_values) do
    for i, col in ipairs(cols) do
      padding[i] = padding[i] or 0
      local len = vim.fn.strdisplaywidth(col)
      if len > padding[i] then
        padding[i] = len
      end
    end
  end

  return padding
end

---Format a single item, meant to be used in `vim.ui.select()`
---@param item LegendaryItem
---@param formatter ItemFormatter
---@param padding integer[]
---@param mode string
---@return string
function M.format_item(item, formatter, padding, mode)
  formatter = formatter or M.default_format
  local values = formatter(item, mode)
  local cols = {}
  for i, col in ipairs(values) do
    table.insert(cols, rpad(col, padding[i] or 0))
  end

  local format_str =
    string.format('%%s%s', string.rep(string.format(' %s %%s', Config.col_separator_char), #values - 1))
  return string.format(format_str, unpack(cols))
end

return M
