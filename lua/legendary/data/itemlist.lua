local class = require('legendary.api.middleclass')
local util = require('legendary.util')
local Toolbox = require('legendary.toolbox')

---@alias LegendaryItem Keymap|Command|Augroup|Autocmd|Function

---@class ItemList
local ItemList = class('ItemList')

---@private
function ItemList:initialize()
  self.items = {}
  self.builtins_added = false
  self.duplicate_tracker = {}
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
    if Toolbox.is_augroup(item) then
      local msg = '[legendary.nvim] Augroups should not be added to ItemList used for UI -- this most likely indicates '
        .. 'a programming error, please submit an issue at https://github.com/mrjones2014/legendary.nvim'
      vim.notify(msg)
    else
      if item.description and #item.description > 0 then
        local id = item:id()
        if not self.duplicate_tracker[id] then
          self.duplicate_tracker[id] = true
        end

        table.insert(self.items, item)
      end
    end
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
    return self.items
  end

  return vim.tbl_filter(function(item)
    return util.tbl_all(filters, function(filter)
      return filter(item)
    end)
  end, self.items)
end

---Sort *in place* to move the most
---recent item to the top.
---THIS MODIFIES THE LIST IN PLACE.
---@param most_recent LegendaryItem
function ItemList:sort_inplace_by_recent(most_recent)
  local Sorter = require('legendary.api.sorter')
  self.items = Sorter.mergesort(self.items, function(item)
    return item == most_recent
  end)
end

return ItemList
