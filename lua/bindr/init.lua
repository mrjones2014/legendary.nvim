local M = {
  keymaps = {},
}

local Formatter = require('bindr.formatter').Formatter

function M.bind_single(keymap)
  if not keymap or type(keymap) ~= 'table' then
    return
  end

  keymap.opts = keymap.opts or {}
  if keymap.opts.silent == nil then
    keymap.opts.silent = true
  end
  if keymap.description and #keymap.description > 0 then
    table.insert(M.keymaps, Formatter:new(keymap))
  end
  vim.keymap.set(keymap.mode or 'n', keymap[1], keymap[2], keymap.opts)
end

function M.bind(keymaps)
  if not keymaps or type(keymaps) ~= 'table' then
    return
  end

  if keymaps[1] == nil or type(keymaps[1]) ~= 'table' then
    M.bind_single(keymaps)
    return
  end

  for _, keymap in pairs(keymaps) do
    M.bind_single(keymap)
  end
end

function M.find()
  local win_id = vim.api.nvim_get_current_win()
  vim.ui.select(M.keymaps, {
    prompt = 'Find Key Binding',
  }, function(selected)
    vim.api.nvim_set_current_win(win_id)
    require('bindr.executor').try_execute(selected)
  end)
end

return M
