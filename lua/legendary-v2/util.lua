local M = {}

---Get resolved item description. Checks item.description, item.desc, item.opts.desc
---@param item table
---@return string
function M.get_desc(item)
  return item.description or item.desc or vim.tbl_get(item, 'opts', 'desc') or ''
end

---Helper to return a default value if a boolean is nil
---@param bool boolean|nil
---@param default boolean
---@return boolean
function M.bool_default(bool, default)
  if bool == nil then
    return default
  end

  return bool
end

---Check if all items in the table match predicate
---@generic T
---@param tbl T[]
---@param predicate fun(item:T):boolean
---@return boolean
function M.tbl_all(tbl, predicate)
  for _, item in ipairs(tbl) do
    if not predicate(item) then
      return false
    end
  end

  return true
end

---Check if an item is a Keymap
---@param keymap LegendaryItem
---@return boolean
function M.is_keymap(keymap)
  -- inline require to avoid circular dependency
  return keymap.class == require('legendary-v2.types.keymap')
end

---Check if an item is a Command
---@param cmd LegendaryItem
---@return boolean
function M.is_command(cmd)
  -- inline require to avoid circular dependency
  return cmd.class == require('legendary-v2.types.command')
end

---Check if an item is an Augroup
---@param au LegendaryItem
---@return boolean
function M.is_augroup(au)
  -- inline require to avoid circular dependency
  return au.class == require('legendary-v2.types.augroup')
end

---Check if an item is an Autocmd
---@param autocmd LegendaryItem
---@return boolean
function M.is_autocmd(autocmd)
  -- inline require to avoid circular dependency
  return autocmd.class == require('legendary-v2.types.autocmd')
end

---Check if an item is an Augroup or Autocmd
---@param au_or_autocmd LegendaryItem
---@return boolean
function M.is_augroup_or_autocmd(au_or_autocmd)
  -- inline require to avoid circular dependency
  return au_or_autocmd.class == require('legendary-v2.types.augroup')
    or au_or_autocmd.class == require('legendary-v2.types.autocmd')
end

---Check if an item is a Function
---@param func LegendaryItem
---@return boolean
function M.is_function(func)
  -- inline require to avoid circular dependency
  return func.class == require('legendary-v2.types.function')
end

return M
