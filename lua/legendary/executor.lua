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

local function exec(item, visual_selection)
  local cmd = require('legendary.utils').get_definition(item)

  if type(cmd) == 'function' then
    cmd(visual_selection)
  else
    if item.unfinished then
      -- % is escape character in gsub patterns
      cmd = cmd:gsub('{.*}$', ''):gsub('%[.*%]$', '')

      -- if unfinished command, remove trailing <CR>
      if cmd:sub(#cmd - 3):lower() == '<cr>' then
        cmd = cmd:sub(1, #cmd - 4)
      elseif cmd:sub(#cmd - 1):lower() == '\r' then
        cmd = cmd:sub(1, #cmd - 2)
      end
    end

    cmd = vim.api.nvim_replace_termcodes(cmd, true, false, true)
    vim.api.nvim_feedkeys(cmd, 't', true)
  end
end

--- Attmept to execute the selected item
---@param item LegendaryItem
function M.try_execute(item, visual_selection)
  if not item then
    return
  end

  local mode = item.mode or 'n'
  -- if there's a visual selection, execute in visual mode
  if visual_selection then
    mode = 'v'
  elseif type(mode) == 'table' then
    mode = mode_from_table(mode)
  end

  if mode == nil or (mode ~= 'n' and mode ~= 'i' and mode ~= 'v') then
    require('legendary.utils').notify(
      'Executing keybinds is only supported for insert, normal, and visual mode bindings.',
      vim.log.levels.INFO
    )
    return
  end

  if mode == 'n' then -- normal mode
    vim.cmd('stopinsert')
    exec(item)
  elseif mode == 'i' then -- insert mode
    vim.cmd('startinsert')
    exec(item)
  elseif mode == 'v' then -- visual mode
    vim.cmd('normal v')
    exec(item, visual_selection)
    -- back to normal mode
    require('legendary.utils').send_escape_key()
  end
end

return M
