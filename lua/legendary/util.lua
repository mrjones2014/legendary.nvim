local M = {}

function M.opts_are_equal(keymap, new_keymap)
  for key, _ in pairs(keymap) do
    if keymap[key] ~= new_keymap[key] then
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

return M
