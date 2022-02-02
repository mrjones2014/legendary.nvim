local M = {}

local padding_mode = 0
local padding_keymap = 0

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

function M.update_padding(keymap)
  if not keymap or type(keymap) ~= 'table' or not keymap[1] or keymap.nobind then
    return
  end

  if #keymap[1] > padding_keymap then
    padding_keymap = #keymap[1]
  end

  local modes = mode_str(keymap)
  if #modes > padding_mode then
    padding_mode = #modes
  end
end

M.Formatter = {}
function M.Formatter:new(keymap)
  local item = vim.deepcopy(keymap)

  setmetatable(item, {
    __tostring = function(self_item)
      local description = ''
      if self_item.description ~= nil and type(self_item.description) == 'string' and #self_item.description > 0 then
        description = self_item.description
      else
        description = 'No description provided'
      end

      local modes = mode_str(keymap)
      local key = ''
      if not self_item.nobind then
        key = self_item[1]
      end

      return string.format('modes: %s | %s | %s', rpad(modes, padding_mode), rpad(key, padding_keymap), description)
    end,
  })

  return item
end

return M
