require('legendary.types')
local M = {}

local function mode_from_table(modes: {string}, current_mode: string): string
  if vim.tbl_contains(modes, current_mode) then
    return current_mode
  end

  for _, mode in ipairs(modes) do
    if mode == 'n' or mode == 'i' or require('legendary.utils').is_visual_mode(mode) then
      return mode
    end
  end

  return nil
end

local function exec(item: LegendaryItem, mode: string, visual_selection: table)
  local utils = require('legendary.utils')
  local cmd = utils.get_definition(item as table, mode)
  local opts = utils.resolve_opts(item , mode)

  if mode == 'n' then -- normal mode
    vim.cmd('stopinsert')
  elseif mode == 'i' then -- insert mode
    vim.cmd('startinsert')
  elseif utils.is_visual_mode(mode) then -- visual mode
    vim.cmd('normal! gv')
    -- if failed to go to visual mode, return
    if not utils.is_visual_mode((vim.fn.mode() as string | nil) or '') then
      utils.notify('Failed to enter visual mode, aborting execution.')
      return
    end
  end

  if type(cmd) == 'function' then
    (cmd as function(marks: table): nil)(visual_selection)
  else
    if (item as table).unfinished then
      vim.cmd('stopinsert')
      -- % is escape character in gsub patterns
      -- strip param names between [] or {}
      cmd = (cmd as string):gsub('{.*}$', ''):gsub('%[.*%]$', '')
      -- if unfinished command, remove trailing <CR>
      cmd = require('legendary.utils').strip_trailing_cr(cmd)
    elseif opts.expr then
      cmd = (item as {string})[1]
    elseif vim.startswith(item.kind, 'legendary.command') then
      vim.cmd(require('legendary.utils').strip_leading_cmd_char(cmd as string))
      return
    end

    cmd = vim.api.nvim_replace_termcodes(cmd as string, true, false, true)
    vim.api.nvim_feedkeys(cmd, 't', true)
  end
end

--- Attmept to execute the selected item
---@param item LegendaryItem
function M.try_execute(item: LegendaryItem, current_buf: integer, visual_selection: table | nil, current_mode: string, current_cursor_pos: {integer, integer})
  if not item then
    return
  end

  local mode = (item as table).mode or 'n'
  -- if there's a visual selection, execute in visual mode
  if visual_selection then
    mode = 'v'
  elseif type(mode) == 'table' then
    mode = mode_from_table(mode as {string})
  end

  if mode == 'x' and visual_selection then
    mode = 'v'
  end

  if mode == nil or (mode ~= 'n' and mode ~= 'i' and not require('legendary.utils').is_visual_mode(mode as string)) then
    require('legendary.utils').notify(
      'Executing keybinds is only supported for insert, normal, and visual mode bindings.',
      vim.log.levels.INFO
    )
    return
  end

  exec(item, mode as string, visual_selection)

  vim.schedule(function()
    if vim.api.nvim_get_current_buf() ~= current_buf then
      return
    end

    -- only if we're back in same buffer
    pcall(vim.api.nvim_win_set_cursor, 0, current_cursor_pos)
    if current_mode == 'n' then
      vim.cmd('stopinsert')
    elseif current_mode == 'i' then
      vim.cmd('startinsert')
    end
  end)
end

return M
