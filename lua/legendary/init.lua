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

  if not keymap.nobind then
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
  vim.ui.select(M.keymaps, {
    prompt = 'Find Key Binding',
  }, function(selected)
    require('legendary.executor').try_execute(selected)
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
