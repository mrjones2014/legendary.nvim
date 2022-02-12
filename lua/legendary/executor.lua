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

local function exec(keymap)
  local cmd = require('legendary.util').get_definition(keymap)

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

    if keymap.unfinished then
      -- % is escape character in gsub patterns
      cmd = cmd:gsub('{.*}$', ''):gsub('%[.*%]$', '')
    end

    if keymap.unfinished or (cmd:sub(1, 5):lower() ~= '<cmd>' and cmd:sub(1, 1) ~= ':') then
      vim.api.nvim_feedkeys(cmd, 't', true)
    else
      vim.cmd(string.format("execute '%s'", cmd))
    end
  end
end

function M.try_execute(keymap)
  if not keymap then
    return
  end

  local mode = keymap.mode or 'n'
  if type(mode) == 'table' then
    mode = mode_from_table(mode)
  end

  if mode == nil or (mode ~= 'n' and mode ~= 'i') then
    vim.notify('Executing keybinds is only supported for insert and normal mode bindings.', vim.log.levels.INFO)
    return
  end

  if mode == 'n' then
    vim.cmd('stopinsert')
    exec(keymap)
    return
  end

  vim.cmd('startinsert')
  exec(keymap)
end

return M
