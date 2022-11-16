local class = require('legendary.vendor.middleclass')
local util = require('legendary.util')
local Toolbox = require('legendary.toolbox')
local Sorter = require('legendary.vendor.sorter')

---@alias LegendaryItem Keymap|Command|Augroup|Autocmd|Function

---@class ItemList
local ItemList = class('ItemList')

---@private
function ItemList:initialize()
  self.items = {}
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

---@alias LegendaryItemFilter fun(item:LegendaryItem):boolean

---Filter the ItemList. Returns a *new* ItemList,
---self remains immutable.
---@param filters LegendaryItemFilter|LegendaryItemFilter[]
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
function ItemList:sort_inplace_by_recent()
  self:sort_inplace({ most_recent_first = true })
end

---@class LegendarySorterOpts
---@field most_recent_first boolean whether to sort the most recently selected item to the top
---@field user_items_first boolean whether to sort user-defined items before built-ins
---@field item_type_bias 'keymap'|'command'|'autocmd' Boost the sort score of the specified item type
---@field custom fun(item1:LegendaryItem,item2:LegendaryItem):boolean Custom sort fn, return `true` if `item1` is "less than" `item2`.

---Sort the list *IN PLACE*.
--THIS MODIFIES THE LIST IN PLACE.
---@param opts LegendarySorterOpts
function ItemList:sort_inplace(opts)
  opts = opts or {}
  if #vim.tbl_keys(opts) == 0 then
    -- nothing to do if no sorting requested
    return
  end

  -- inline require to avoid circular dependency
  local State = require('legendary.data.state')

  local items = self.items

  local comparators = {}

  -- set up comparators for each opts field

  if opts.user_items_first then
    table.insert(comparators, function(item, item2)
      return not item.builtin and item2.builtin
    end)
  end

  if opts.item_type_bias then
    vim.validate({
      item_type_bias = {
        opts.item_type_bias,
        function(item_type_bias)
          return item_type_bias == 'keymap' or item_type_bias == 'command' or item_type_bias == 'autocmd'
        end,
      },
    })
    table.insert(comparators, function(item, item2)
      if item == item2 then
        return false
      end

      if opts.item_type_bias == 'keymap' then
        return Toolbox.is_keymap(item) and not Toolbox.is_keymap(item2)
      elseif opts.item_type_bias == 'command' then
        return Toolbox.is_command(item) and not Toolbox.is_command(item2)
      else
        return Toolbox.is_autocmd(item) and not Toolbox.is_autocmd(item2)
      end
    end)
  end

  if opts.custom then
    table.insert(comparators, opts.custom)
  end

  -- do the sorting

  local function combined_comparator(item, item2)
    if item == item2 then
      return false
    end

    local result = false
    for _, comparator in ipairs(comparators) do
      result = result or comparator(item, item2)
    end

    return result
  end

  local ok, sorted = pcall(Sorter.mergesort, items, combined_comparator)
  if not ok then
    vim.api.nvim_err_write(string.format('[legendary.nvim] Failed to sort items: %s\n', vim.inspect(sorted)))
  else
    items = sorted
  end

  -- sort by most recent last, and after other sorts are done
  -- if most recent is already at top, nothing to do, and attempting to sort will cause
  -- an error since it doesn't need to be sorted
  if opts.most_recent_first and State.most_recent_item and State.most_recent_item ~= self.items[1] then
    items = Sorter.mergesort(items, function(item)
      return item == State.most_recent_item
    end)
  end

  self.items = items
end

return ItemList
