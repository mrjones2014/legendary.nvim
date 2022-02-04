local M = {
  keymaps = {},
}

local Formatter = require('legendary.formatter').Formatter

function M.bind_single(keymap)
  require('legendary.formatter').update_padding(keymap)
  if not keymap or type(keymap) ~= 'table' then
    return
  end

  if require('legendary.util').contains_duplicates(M.keymaps, keymap) then
    return
  end

  keymap.opts = keymap.opts or {}
  if keymap.opts.silent == nil then
    keymap.opts.silent = true
  end
  if keymap.description and #keymap.description > 0 then
    table.insert(M.keymaps, Formatter:new(keymap))
  end

  if not keymap.nobind and not keymap.builtin then
    vim.keymap.set(keymap.mode or 'n', keymap[1], keymap[2], keymap.opts)
  end
end

function M.bind(keymaps)
  if not keymaps or type(keymaps) ~= 'table' then
    return
  end

  if not keymaps[1] or type(keymaps[1]) ~= 'table' then
    M.bind_single(keymaps)
  else
    for _, keymap in pairs(keymaps) do
      M.bind_single(keymap)
    end
  end
end

function M.find()
  local current_mode = vim.fn.mode()
  local cursor_position = vim.api.nvim_win_get_cursor(0)
  local current_window_num = vim.api.nvim_win_get_number(0)
  vim.ui.select(M.keymaps, {
    prompt = require('legendary.config').select_prompt,
  }, function(selected)
    require('legendary.executor').try_execute(selected)

    -- only restore cursor position if we're going back
    -- to the same window
    if vim.api.nvim_win_get_number(0) ~= current_window_num then
      return
    end

    -- restore cursor position, adding 1 to avoid
    -- putting the cursor 1 col to the left of where it was
    vim.api.nvim_win_set_cursor(0, { cursor_position[1], cursor_position[2] + 1 })
    -- if we were in normal or insert mode, go back to it
    if current_mode == 'n' then
      vim.schedule(function()
        vim.cmd('stopinsert')
      end)
    elseif current_mode == 'i' then
      vim.schedule(function()
        vim.cmd('startinsert')
      end)
    end
  end)
end

return M
