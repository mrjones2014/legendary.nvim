local M = {}

function M.opts_are_equal(keymap, new_keymap)
  for key, _ in pairs(keymap or {}) do
    if keymap[key] ~= (new_keymap or {})[key] then
      return false
    end
  end

  return true
end

function M.contains_duplicates(keymaps, new_keymap)
  for _, keymap in pairs(keymaps) do
    if
      keymap[1] == new_keymap[1]
      and keymap[2] == keymap[2]
      and (keymap.mode or 'n') == (new_keymap.mode or 'n')
      and keymap.description == new_keymap.description
      and M.opts_are_equal(keymap.opts, new_keymap.opts)
    then
      return true
    end
  end

  return false
end

function M.is_user_keymap(keymap)
  return keymap ~= nil
    and type(keymap) == 'table'
    and type(keymap[1]) == 'string'
    and (type(keymap[2]) == 'string' or type(keymap[2]) == 'function')
end

function M.set_keymap(keymap)
  if not M.is_user_keymap(keymap) then
    return
  end

  keymap.opts = keymap.opts or {}
  -- set default options
  if keymap.opts.silent == nil then
    keymap.opts.silent = true
  end

  vim.keymap.set(keymap.mode or 'n', keymap[1], keymap[2], keymap.opts)
end

function M.get_definition(keymap)
  if M.is_user_keymap(keymap) then
    return keymap[2]
  end

  return keymap[1]
end

return M
