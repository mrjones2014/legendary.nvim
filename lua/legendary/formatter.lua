local M = {}

local padding = {}

--- for unit tests only, should not be called from plugin code!
function M.__clear_padding()
  padding = {}
end

--- Compute the length of the given string rendered as UTF-8
---@param str string
---@return number
function M.utf8_len(str)
  str = str or ''
  local count = 0
  for _ in string.gmatch(str, '([%z\1-\127\194-\244][\128-\191]*)') do
    count = count + 1
  end

  return count
end

---Right-pad strings to specified length
---@param str string the string to pad
---@param len number the padding value to use
---@return string the padded string
function M.rpad(str, len)
  return string.format('%s%s', str, string.rep(' ', len - M.utf8_len(str)))
end

local function col1_str(item)
  if vim.startswith(item.kind or '', 'legendary.command') then
    return '<cmd>'
  end

  if vim.startswith(item.kind or '', 'legendary.autocmd') then
    local events = item[1]
    if type(events) == 'table' then
      events = table.concat(events, ', ')
    end

    return events
  end

  local modes = item.mode or 'n'
  if type(modes) == 'table' then
    modes = table.concat(modes, ', ')
  end

  return modes
end

local function col2_str(item)
  if vim.startswith(item.kind or '', 'legendary.autocmd') then
    local patterns = item.opts and item.opts.pattern or '*'
    if type(patterns) == 'table' then
      patterns = table.concat(patterns, ', ')
    end

    return patterns
  end

  return item[1]
end

local function col3_str(item)
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
function M.get_default_format_values(item)
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
function M.get_format_values(item)
  local formatter = require('legendary.config').formatter
  if formatter and type(formatter) == 'function' then
    local values = formatter(item)
    -- normalize values
    for i, value in pairs(values) do
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
function M.update_padding(item)
  local values = M.get_format_values(item)
  for i, value in pairs(values) do
    local len = M.utf8_len(value)
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
function M.get_padding()
  return vim.deepcopy(padding)
end

--- Format a LegendaryItem to a string
---@param item LegendaryItem
---@return string
function M.format(item)
  local values = M.get_format_values(item)

  local strs = {}
  for i, value in pairs(values) do
    table.insert(strs, M.rpad(value, padding[i] or 0))
  end

  local format_str = string.format('%%s%s', string.rep(' │ %s', #values - 1))
  return string.format(format_str, require('legendary.helpers').unpack(strs))
end

return M
