local Toolbox = require('legendary.toolbox')
local Log = require('legendary.log')
local util = require('legendary.util')

local M = {}

---@class LegendaryEditorContext
---@field buf integer
---@field mode string
---@field cursor_pos integer[] { row, col }
---@field marks integer[]|nil

---Build a context object containing information about the editor
---state *before* triggering the finder so that it can be
---restored before executing the item.
---@return table
function M.build_pre_context()
  return {
    buf = vim.api.nvim_get_current_buf(),
    mode = vim.fn.mode(),
    cursor_pos = vim.api.nvim_win_get_cursor(vim.api.nvim_get_current_win()),
    marks = Toolbox.get_marks(),
  }
end

---Restore editor state based on context
---@param context LegendaryEditorContext
function M.restore_context(context, callback)
  Toolbox.set_marks(context.marks)
  if vim.startswith(context.mode, 'n') then
    vim.cmd('stopinsert')
  elseif Toolbox.is_visual_mode(context.mode) then
    vim.cmd('normal! gv')
  elseif vim.startswith(context.mode, 'i') then
    vim.cmd('startinsert')
  else
    Log.info('Sorry, only normal, insert, and visual mode executions are supported by legendary.nvim.')
    return
  end

  vim.schedule(function()
    callback()
  end)
end

---Execute an item
---@param item LegendaryItem
---@param context LegendaryEditorContext
function M.exec_item(item, context)
  vim.schedule(function()
    M.restore_context(context, function()
      if Toolbox.is_function(item) then
        item.implementation()
      elseif Toolbox.is_command(item) then
        local cmd = item:vim_cmd()
        if item.unfinished == true then
          util.exec_feedkeys(string.format(':%s ', cmd))
        else
          -- if in visual mode and the command supports range, add marks
          if
            vim.tbl_get(item, 'opts', 'range') == true
            and Toolbox.is_visual_mode(context.mode)
            and not vim.startswith(cmd, "'<,'>")
          then
            cmd = string.format("'<,'>%s", cmd)
          end
          vim.cmd(cmd)
        end
      elseif Toolbox.is_keymap(item) then
        util.exec_feedkeys(item.keys)
      elseif Toolbox.is_autocmd(item) then
        local impl = item.implementation
        if type(impl) == 'function' then
          impl()
        else
          util.exec_feedkeys(impl --[[@as string]])
        end
      else
        Log.debug('Unsupported item type selected from finder UI: %s', item)
      end
    end)
  end)
end

return M
