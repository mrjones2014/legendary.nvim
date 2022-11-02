local class = require('legendary-v2.middleclass')
local util = require('legendary-v2.util')

---@alias LegendaryItem Keymap|Command|Augroup|Autocmd|Function

---@class ItemList
local ItemList = class('ItemList')

---@private
function ItemList:initialize()
  self.items = {}
end

---Create a new ItemList
---@return ItemList
function ItemList:create() -- luacheck: no unused
  return ItemList()
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

    -- TODO optimize this :/
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
---self remains immutable.
---@param filters ItemFilter|ItemFilter[]
---@return LegendaryItem[]
function ItemList:filter(filters)
  -- wrap in list to make following code more succinct
  if type(filters) ~= 'table' then
    filters = { filters }
  end

  if #filters == 0 then
    return self:get()
  end

  return vim.tbl_filter(function(item)
    return util.tbl_all(filters, function(filter)
      return filter(item)
    end)
  end, self.items)
end

---Get a *copy* of the item list
---@return LegendaryItem[]
function ItemList:get()
  return vim.deepcopy(self.items)
end

return ItemList
