local M = {}

local function mode_from_table(modes)
  for _, mode in pairs(modes) do
    if mode == 'n' then
      return mode
    end

    if mode == 'i' then
      return mode
    end
  end

  return nil
end

local function exec(item)
  local cmd = require('legendary.util').get_definition(item)

  if type(cmd) == 'function' then
    cmd()
  else
    if cmd:sub(#cmd - 3):lower() == '<cr>' then
      cmd = cmd:sub(1, #cmd - 4)
    elseif cmd:sub(#cmd - 1):lower() == '\r' then
      cmd = cmd:sub(1, #cmd - 2)
    end

    local cmd_stripped = require('legendary.util').strip_leading_cmd_char(cmd)
    if #cmd ~= #cmd_stripped then
      cmd = cmd_stripped
      cmd = string.format(':%s', cmd)
    end
    cmd = vim.api.nvim_replace_termcodes(cmd, true, false, true)

    if item.unfinished then
      -- % is escape character in gsub patterns
      cmd = cmd:gsub('{.*}$', ''):gsub('%[.*%]$', '')
    end

    if item.unfinished or (cmd:sub(1, 5):lower() ~= '<cmd>' and cmd:sub(1, 1) ~= ':') then
      vim.api.nvim_feedkeys(cmd, 't', true)
    else
      vim.cmd(string.format('execute %q', cmd))
    end
  end
end

--- Attmept to execute the selected item
---@param item LegendaryItem
function M.try_execute(item)
  if not item then
    return
  end

  local mode = item.mode or 'n'
  if type(mode) == 'table' then
    mode = mode_from_table(mode)
  end

  if mode == nil or (mode ~= 'n' and mode ~= 'i') then
    require('legendary.util').notify(
      'Executing keybinds is only supported for insert and normal mode bindings.',
      vim.log.levels.INFO
    )
    return
  end

  if mode == 'n' then
    vim.cmd('stopinsert')
    exec(item)
    return
  end

  vim.cmd('startinsert')
  exec(item)
end

return M
