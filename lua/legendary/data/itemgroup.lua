local class = require('legendary.vendor.middleclass')
local ItemList = require('legendary.data.itemlist')
local Keymap = require('legendary.data.keymap')
local Command = require('legendary.data.command')
local Function = require('legendary.data.function')

---@class ItemGroup
---@field name string
---@field items ItemList
---@field class ItemGroup
local ItemGroup = class('ItemGroup')

---Parse an ItemGroup
---@param tbl table
function ItemGroup:parse(tbl)
  vim.validate({
    itemgroup = { tbl.itemgroup, { 'string' } },
    keymaps = { tbl.keymaps, { 'table' }, true },
    commands = { tbl.commands, { 'table' }, true },
    funcs = { tbl.funcs, { 'table' }, true },
  })

  local instance = ItemGroup()

  instance.name = tbl.itemgroup
  instance.items = ItemList:create()
  local keymaps = vim.tbl_map(function(keymap)
    return Keymap:parse(keymap)
  end, tbl.keymaps or {})
  local commands = vim.tbl_map(function(cmd)
    return Command:parse(cmd)
  end, tbl.commands or {})
  local funcs = vim.tbl_map(function(fn)
    return Function:parse(fn)
  end, tbl.funcs or {})
  instance.items:add(keymaps)
  instance.items:add(commands)
  instance.items:add(funcs)
  return instance
end

---Apply the items in the ItemGroup
---@return ItemGroup
function ItemGroup:apply()
  vim.tbl_map(function(item)
    item:apply()
  end, self.items.items)
  return self
end

return ItemGroup
