---@mod legendary.formatter require('legendary.formatter')

require('legendary.types')
local M = {}

local padding: {integer} = {}

--- for unit tests only, should not be called from plugin code!
function M.__clear_padding()
  padding = {}
end

---Right-pad strings to specified length
---@param str string the string to pad
---@param len integer the padding value to use
---@return string the padded string
function M.rpad(str: string, len: integer): string
  return string.format('%s%s', str, string.rep(' ', len - (vim.fn.strdisplaywidth(str) as integer)))
end

local function col1_str(item: LegendaryItem): string
  if vim.startswith(item.kind or '', 'legendary.command') then
    return '<cmd>'
  end

  if vim.startswith(item.kind or '', 'legendary.autocmd') then
    local events = (item as LegendaryAutocmd)[1]
    if type(events) == 'table' then
      events = table.concat(events as {string}, ', ')
    end

    return events as string
  end

  local modes = (item as LegendaryKeymap).mode or 'n'
  if type(modes) == 'table' then
    modes = table.concat(modes as {string}, ', ')
  end

  if type((item as LegendaryKeymap)[2]) == 'table' then
    modes = table.concat(vim.tbl_keys((item as LegendaryKeymap)[2] as {string:any}), ', ')
  end

  return modes as string
end

local function col2_str(item: LegendaryItem): string
  if vim.startswith(item.kind or '', 'legendary.autocmd') then
    local patterns = (item as table).opts and ((item as table).opts as table).pattern or '*'
    if type(patterns) == 'table' then
      patterns = table.concat(patterns as {string}, ', ')
    end

    return patterns as string
  end

  return (item as table)[1] as string
end

local function col3_str(item: LegendaryItem): string
  return item.description or ''
end

--- Default implementation of config.formatter
--- Column one:
---   - Keymaps => modes
---   - Commands => '<cmd>'
---   - Autocmds => events
--- Column 2:
---   - Keymaps => key codes
---   - Commands => command
---   - Autocmds => patterns
--- Column 3:
---   - All => description
---@param item LegendaryItem
---@return table the values to format
function M.get_default_format_values(item: LegendaryItem): {string}
  return {
    col1_str(item),
    col2_str(item),
    col3_str(item),
  }
end

--- Get the column values to be formatted
--- for item. Uses config.formatter if not nil,
--- default implementation otherwise.
---@param item LegendaryItem
---@return table the values to format
function M.get_format_values(item: LegendaryItem, mode: string, one_shot_formatter: LegendaryFormatter | nil): {string}
  if one_shot_formatter ~= nil then
    local fmt = one_shot_formatter as LegendaryFormatter
    local values = fmt(item, mode)
    -- normalize the list in case there are missing indices
    return vim.list_extend({}, values)
  end

  local formatter = require('legendary.config').formatter
  if formatter and type(formatter) == 'function' then
    local values = formatter(item, mode)
    -- normalize values
    for i, value in ipairs(values) do
      if value == nil then
        values[i] = ''
      end

      if type(value) ~= 'string' then
        values[i] = tostring(value)
      end
    end

    return values
  end

  return M.get_default_format_values(item)
end

--- Update cached column paddings.
---@param item LegendaryItem
function M.update_padding(item: LegendaryItem)
  local values = M.get_format_values(item)
  for i, value in ipairs(values) do
    local len = vim.fn.strdisplaywidth(value) as integer
    if len > (padding[i] or 0) then
      padding[i] = len
    end
  end
end

--- Returns a READ-ONLY COPY of the current padding values.
--- Note that this is a COPY of the table so it will not update,
--- and writing to it will not do anything. Padding is managed
--- internally by the formatter and should not be modified manually.
---@return table a table containing the padding value for each column.
function M.get_padding(): {integer}
  return vim.deepcopy(padding)
end

--- Format a LegendaryItem to a string
---@param item LegendaryItem
---@return string
function M.format(item: LegendaryItem, mode: string, formatter: LegendaryFormatter | nil): string
  local values = M.get_format_values(item, mode, formatter)

  local strs = {}
  for i, value in ipairs(values) do
    table.insert(strs, M.rpad(value, padding[i] or 0))
  end

  local format_str = string.format('%%s%s', string.rep(' │ %s', #values - 1))
  return string.format(format_str, unpack(strs))
end

return M
