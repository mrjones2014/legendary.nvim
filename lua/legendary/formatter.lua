local M = {}

local padding_col1 = 0
local padding_col2 = 0

local function rpad(str, len)
  return string.format('%s%s', string.rep(' ', len - #str), str)
end

local function mode_str(keymap)
  local modes = keymap.mode or 'n'
  if type(modes) == 'table' then
    modes = table.concat(modes, ', ')
  end

  return modes
end

local function events_str(autocmd)
  local events = autocmd[1]
  if type(events) == 'table' then
    events = table.concat(events, ', ')
  end

  return events
end

local function pattern_str(autocmd)
  local patterns = autocmd.opts.pattern
  if type(patterns) == 'table' then
    patterns = table.concat(patterns, ', ')
  end

  return patterns
end

function M.update_padding(legendary_item)
  if require('legendary.util').is_autocmd(legendary_item) then
    local events = events_str(legendary_item)
    if #events > padding_col1 then
      padding_col1 = #events
    end

    local patterns = pattern_str(legendary_item)
    if #patterns > padding_col2 then
      padding_col2 = #patterns
    end

    return
  end

  local modes = mode_str(legendary_item)
  if #modes > padding_col1 then
    padding_col1 = #modes
  end

  if #legendary_item[1] > padding_col2 then
    padding_col2 = #legendary_item[1]
  end
end

--- Create a formatter for a given item
---@param selected_item LegendaryItem
---@return LegendaryItem
function M.Formatter(selected_item)
  local item = vim.deepcopy(selected_item)

  setmetatable(item, {
    __tostring = function(self_item)
      local description
      if self_item.description ~= nil and type(self_item.description) == 'string' and #self_item.description > 0 then
        description = self_item.description
      else
        description = 'No description provided'
      end

      if self_item.opts and self_item.opts.pattern then
        local events = events_str(self_item)
        local patterns = pattern_str(self_item)
        return string.format('%s │ %s │ %s', rpad(events, padding_col1), rpad(patterns, padding_col2), description)
      end
      if require('legendary.util').is_autocmd(self_item) then
        return 'autocmd formatter search for me'
      end

      local modes = mode_str(item)
      local key = self_item[1]

      return string.format('modes: %s │ %s │ %s', rpad(modes, padding_col1), rpad(key, padding_col2), description)
    end,
  })

  return item
end

return M
