local M = {}

local padding_col1 = 0
local padding_col2 = 0

local function lpad(str, len)
  return string.format('%s%s', str, string.rep(' ', len - #str))
end

local function col1_str(item)
  if item.kind == 'legendary-command' then
    return '<cmd>'
  end

  if item.kind == 'legendary-autocmd' then
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
  if item.kind == 'legendary-autocmd' then
    local patterns = item.opts and item.opts.pattern or '*'
    if type(patterns) == 'table' then
      patterns = table.concat(patterns, ', ')
    end

    return patterns
  end

  return item[1]
end

function M.update_padding(legendary_item)
  local col1 = col1_str(legendary_item)
  if #col1 > padding_col1 then
    padding_col1 = #col1
  end

  local col2 = col2_str(legendary_item)
  if #col2 > padding_col2 then
    padding_col2 = #legendary_item[1]
  end
end

--- Format a LegendaryItem to a string
---@param item LegendaryItem
function M.tostring(item)
  local col1 = col1_str(item)
  local col2 = col2_str(item)

  return string.format('%s │ %s │ %s', lpad(col1, padding_col1), lpad(col2, padding_col2), item.description or '')
end

return M
