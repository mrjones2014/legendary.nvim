local class = require('legendary.vendor.middleclass')
local ItemList = require('legendary.data.itemlist')
local Keymap = require('legendary.data.keymap')
local Command = require('legendary.data.command')
local Function = require('legendary.data.function')

---@class ItemGroup
---@field name string
---@field items ItemList
---@field icon string|nil
---@field description string|nil
---@field class ItemGroup
local ItemGroup = class('ItemGroup')

---Parse an ItemGroup
---@param tbl table
function ItemGroup:parse(tbl) -- luacheck: no unused
  vim.validate({
    itemgroup = { tbl.itemgroup, { 'string' } },
    icon = { tbl.icon, { 'string' }, true },
    description = { tbl.description, { 'string' }, true },
    keymaps = { tbl.keymaps, { 'table' }, true },
    commands = { tbl.commands, { 'table' }, true },
    funcs = { tbl.funcs, { 'table' }, true },
  })

  local instance = ItemGroup()

  instance.name = tbl.itemgroup
  instance.icon = tbl.icon
  instance.description = tbl.description
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
  self.items:iter(function(item)
    item:apply()
  end)
  return self
end

---Get a unique ID for the item group
function ItemGroup:id()
  return self.name
end

function ItemGroup:frecency_id()
  return self.name
end

return ItemGroup
