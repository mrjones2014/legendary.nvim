local M = {}

local padding_mode = 0
local padding_keymap = 0

local function rpad(str, len)
  return string.format('%s%s', string.rep(' ', len - #str), str)
end

function M.init_padding(items)
  if not items or type(items) ~= 'table' then
    return
  end

  if not items[1] or type(items[1]) ~= 'table' then
    if #items[1] > padding_keymap then
      padding_keymap = #items[1]
    end
    return
  end

  for _, item in pairs(items) do
    if #item[1] > padding_keymap then
      padding_keymap = #item[1]
    end
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

      local modes = self_item.mode or 'n'
      if type(modes) == 'table' then
        modes = table.concat(modes, ', ')
      end

      if #modes > padding_mode then
        padding_mode = #modes
      end

      if #self_item[1] > padding_keymap then
        padding_keymap = #self_item[1]
      end

      return string.format(
        'modes: %s | %s | %s',
        rpad(modes, padding_mode),
        rpad(self_item[1], padding_keymap),
        description
      )
    end,
  })

  return item
end

return M
