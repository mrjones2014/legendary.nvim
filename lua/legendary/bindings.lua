local M = {
  keymaps = {},
}

local Formatter = require('legendary.formatter').Formatter

function M.bind_single(keymap)
  if not keymap or type(keymap) ~= 'table' or require('legendary.util').contains_duplicates(M.keymaps, keymap) then
    return
  end

  require('legendary.formatter').update_padding(keymap)

  if keymap.description and #keymap.description > 0 then
    table.insert(M.keymaps, Formatter:new(keymap))
  end

  require('legendary.util').set_keymap(keymap)
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
    -- vim.schedule so that the select UI closes before we do anything
    vim.schedule(function()
      require('legendary.executor').try_execute(selected)

      -- only restore cursor position if we're going back
      -- to the same window
      if vim.api.nvim_win_get_number(0) ~= current_window_num then
        return
      end

      -- some commands close the buffer, in those cases this will fail
      -- so wrap it in pcall
      pcall(function()
        vim.api.nvim_win_set_cursor(0, cursor_position)
        -- if we were in normal or insert mode, go back to it
        if current_mode == 'n' then
          vim.cmd('stopinsert')
        elseif current_mode == 'i' then
          vim.cmd('startinsert')
        end
      end)
    end)
  end)
end

return M
