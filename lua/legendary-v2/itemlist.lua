local class = require('legendary-v2.middleclass')
local util = require('legendary-v2.util')
local Augroup = require('legendary-v2.types.augroup')
local Keymap = require('legendary-v2.types.keymap')
local Command = require('legendary-v2.types.command')

---@alias LegendaryItem Keymap|Command|Augroup|Autocmd|Function

---@class ItemList
local ItemList = class('ItemList')

---@private
function ItemList:initialize()
  self.items = {}
  self.builtins_added = false
end

---Create a new ItemList
---@return ItemList
function ItemList:create() -- luacheck: no unused
  return ItemList()
end

---Optimized to skip validation for builtins
function ItemList:add_builtins()
  if self.builtins_added then
    return
  end

  local Builtins = require('legendary-v2.builtins')
  ---@diagnostic disable
  self.items = vim.list_extend(
    self.items,
    vim.list_extend(
      vim.tbl_map(function(keymap)
        return Keymap:parse(keymap)
      end, Builtins.builtin_keymaps),
      vim.tbl_map(function(command)
        return Command:parse(command)
      end, Builtins.builtin_commands)
    )
  )
  ---@diagnostic enable

  self.builtins_added = true
end

---Add an item to the ItemList. This function
---handles excluding duplicate items and items without descriptions.
---@param items LegendaryItem[]
function ItemList:add(items)
  if #items == 0 then
    return
  end

  ---@type LegendaryItem
  for _, item in ipairs(items) do
    if not item.description or #item.description == 0 then
      goto add_loop_continue
    end

    -- TODO this sucks, optimize this :/
    local existing_items = vim.tbl_filter(function(existing_item)
      return item.class == existing_item.class and vim.inspect(existing_item) == vim.inspect(item)
    end, self.items)

    if #existing_items > 0 then
      goto add_loop_continue
    end

    table.insert(self.items, item)

    ::add_loop_continue::
  end
end

---@alias ItemFilter fun(item:LegendaryItem):boolean

---Filter the ItemList. Returns a *new* ItemList,
---self remains immutable. Filters to runnable items by default.
---@param filters ItemFilter|ItemFilter[]
---@return LegendaryItem[]
function ItemList:filter(filters)
  -- wrap in list to make following code more succinct
  if type(filters) ~= 'table' then
    filters = { filters }
  end

  if #filters == 0 then
    return self:runnables()
  end

  return vim.tbl_filter(function(item)
    return util.tbl_all(filters, function(filter)
      return filter(item)
    end)
  end, self:runnables())
end

---Get a *copy* of the item list
---@return LegendaryItem[]
function ItemList:get()
  return vim.deepcopy(self.items)
end

---Get executable items, e.g. augroups are collapsed to the autocmds they contain.
function ItemList:runnables()
  local runnables = {}

  for _, item in ipairs(self.items) do
    if item.class == Augroup then
      runnables = vim.list_extend(runnables, item.autocmds, 1, #item.autocmds)
    else
      table.insert(runnables, item)
    end
  end

  return runnables
end

return ItemList
