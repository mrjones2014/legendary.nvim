local Toolbox = require('legendary.toolbox')
local Log = require('legendary.log')
local Config = require('legendary.config')
local State = require('legendary.data.state')
local util = require('legendary.util')

local function update_item_frecency_score(item)
  if Config.sort.frecency ~= false then
    if require('legendary.api.db').is_supported() then
      Log.trace('Updating scoring data for selected item.')
      local DbClient = require('legendary.api.db.client').get_client()
      -- if bootstrapping fails, bail
      if not require('legendary.api.db').is_supported() then
        Log.debug(
          'Config.sort.frecency is enabled, but sqlite is not available or database could not be opened, '
            .. 'frecency is automatically disabled.'
        )
        return
      end
      DbClient.update_item_score(item)
    else
      Log.debug(
        'Config.sort.frecency is enabled, but sqlite is not available or database could not be opened, '
          .. 'frecency is automatically disabled.'
      )
    end
  end
end

local M = {}

---@class LegendaryEditorContext
---@field buf integer
---@field buftype string
---@field filetype string
---@field mode string
---@field cursor_pos integer[] { row, col }
---@field marks integer[]|nil

---Build a context object containing information about the editor
---state *before* triggering the finder so that it can be
---restored before executing the item.
---@param buf number buffer ID to build context for, used only for testing
---@overload fun():LegendaryEditorContext
---@return table
function M.build_context(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  return {
    buf = buf,
    buftype = vim.api.nvim_buf_get_option(buf, 'buftype') or '',
    filetype = vim.api.nvim_buf_get_option(buf, 'filetype') or '',
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
    -- we can't just use `gv` since vim.ui.select aborts visual mode without any trace
    vim.cmd(string.format('normal! %s%s', context.mode, vim.api.nvim_replace_termcodes('<esc>', true, false, true)))
    Toolbox.set_marks(context.marks)
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
      State.last_executed_item = item
      update_item_frecency_score(item)
      if Toolbox.is_function(item) then
        item.implementation()
      elseif Toolbox.is_command(item) then
        local cmd = (item--[[@as Command]]):vim_cmd()
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
        util.exec_feedkeys(item.keys, item.builtin)
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
  return 'g@'
end

---Repeat execution of the previously selected item. By default, only executes if the previously used filters
---still return true.
---@param ignore_filters boolean|nil whether to ignore the filters used when selecting the item, default false
function M.repeat_previous(ignore_filters)
  if State.last_executed_item then
    if not ignore_filters and State.most_recent_filters then
      for _, filter in ipairs(State.most_recent_filters) do
        -- if any filter does not match, abort executions
        local err, matches = pcall(filter, State.last_executed_item)
        if not err and not matches then
          Log.warn(
            'Previously executed item no longer matches previously used filters, use `:LegendaryRepeat!`'
              .. " or `require('legendary').repeat_previous(true)` to execute anyway."
          )
          return
        end
      end
    end
    local context = M.build_context()
    M.exec_item(State.last_executed_item, context)
  end
end

return M
