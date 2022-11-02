local Keymap = require('legendary-v2.types.keymap')
local Command = require('legendary-v2.types.command')
local Augroup = require('legendary-v2.types.augroup')
local Autocmd = require('legendary-v2.types.autocmd')
local Function = require('legendary-v2.types.function')

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
  return keymap.class == Keymap
end

---Check if an item is a Command
---@param cmd LegendaryItem
---@return boolean
function M.is_command(cmd)
  return cmd.class == Command
end

---Check if an item is an Augroup
---@param au LegendaryItem
---@return boolean
function M.is_augroup(au)
  return au.class == Augroup
end

---Check if an item is an Autocmd
---@param autocmd LegendaryItem
---@return boolean
function M.is_autocmd(autocmd)
  return autocmd.class == Autocmd
end

---Check if an item is an Augroup or Autocmd
---@param au_or_autocmd LegendaryItem
---@return boolean
function M.is_augroup_or_autocmd(au_or_autocmd)
  return au_or_autocmd.class == Augroup or au_or_autocmd.class == Autocmd
end

---Check if an item is a Function
---@param func LegendaryItem
---@return boolean
function M.is_function(func)
  return func.class == Function
end

return M
