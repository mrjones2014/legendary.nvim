local M = {}

function M.opts_are_equal(keymap, new_keymap)
  for key, _ in pairs(keymap or {}) do
    if key ~= 'buffer' and keymap[key] ~= (new_keymap or {})[key] then
      return false
    end
  end

  return true
end

function M.concat_lists(tbl1, tbl2)
  local result = vim.deepcopy(tbl1)
  for _, item in pairs(tbl2) do
    result[#result + 1] = item
  end

  return result
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

  -- if not a keymap the user wants us to bind, bail
  if type(keymap[2]) ~= 'string' and type(keymap[2]) ~= 'function' then
    return
  end

  keymap.opts = keymap.opts or {}
  -- set default options
  if keymap.opts.silent == nil then
    keymap.opts.silent = true
  end

  vim.keymap.set(keymap.mode or 'n', keymap[1], keymap[2], keymap.opts)
end

function M.strip_leading_cmd_char(cmd_str)
  if type(cmd_str) ~= 'string' then
    return cmd_str
  end

  if cmd_str:sub(1, 5):lower() == '<cmd>' then
    return cmd_str:sub(6)
  elseif cmd_str:sub(1, 1) == ':' then
    return cmd_str:sub(2)
  end

  return cmd_str
end

function M.is_user_command(cmd)
  return cmd ~= nil
    and type(cmd) == 'table'
    and type(cmd[1]) == 'string'
    and (type(cmd[2]) == 'string' or type(cmd[2]) == 'function')
end

function M.set_command(cmd)
  if not M.is_user_command(cmd) then
    return
  end

  vim.api.nvim_add_user_command(M.strip_leading_cmd_char(cmd[1]), cmd[2], {
    desc = cmd.description,
  })
end

function M.get_definition(keymap)
  if M.is_user_keymap(keymap) then
    return keymap[2]
  end

  return keymap[1]
end

return M
