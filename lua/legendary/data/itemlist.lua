local class = require('legendary.vendor.middleclass')
local util = require('legendary.util')
local Toolbox = require('legendary.toolbox')
local Sorter = require('legendary.vendor.sorter')
local Config = require('legendary.config')
local Log = require('legendary.log')

---@alias LegendaryItem Keymap|Command|Augroup|Autocmd|Function|ItemGroup

---@class ItemList
---@field private items LegendaryItem[]
---@field private duplicate_tracker table
---@field private itemgroup_refs table
---@field private sorted boolean
local ItemList = class('ItemList')

---@private
function ItemList:initialize()
  self.items = {}
  self.duplicate_tracker = {}
  self.itemgroup_refs = {}
  self.sorted = true
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
      Log.debug(msg)
    elseif Toolbox.is_itemgroup(item) then
      local group = self.itemgroup_refs[item:id()] or item --[[@as ItemGroup]]
      if group ~= item then
        group.items:add(item.items.items)
        group.icon = group.icon or item.icon
        group.description = group.description or item.description
      else
        self.itemgroup_refs[item.name] = item
        table.insert(self.items, item)
      end
      self.sorted = false
    else
      if item.description and #item.description > 0 and not item.hide then
        local id = item:id()
        if not self.duplicate_tracker[id] then
          self.duplicate_tracker[id] = true
        end

        table.insert(self.items, item)
        self.sorted = false
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

---Sort the list *IN PLACE* according to config.
--THIS MODIFIES THE LIST IN PLACE.
function ItemList:sort_inplace()
  -- inline require to avoid circular dependency
  local State = require('legendary.data.state')
  local opts = Config.sort

  -- if no items have been added, and the most recent item has not changed,
  -- we're already sorted
  if self.sorted and (not opts.most_recent_first or (self.items[1] == State.most_recent_item)) then
    return
  end

  -- check if all sort options are false/nil, if so we don't need to do anything
  if not opts.most_recent_first and not opts.user_items_first and opts.item_type_bias == nil then
    return
  end

  local items = self.items

  if Config.sort.frecency ~= false then
    local has_sqlite, _ = pcall(require, 'sqlite')
    if has_sqlite then
      -- inline require because this module requires sqlite and is a bit heavier
      local DbClient = require('legendary.api.db.client').init()
      local frecency_scores = DbClient.get_item_scores()
      Log.debug('Computed item scores: %s', vim.inspect(frecency_scores))

      local ok, sorted = pcall(
        Sorter.mergesort,
        items,
        ---@param item1 LegendaryItem
        ---@param item2 LegendaryItem
        function(item1, item2)
          local item1_id = DbClient.sql_escape(item1:frecency_id())
          local item2_id = DbClient.sql_escape(item2:frecency_id())
          local item1_score = frecency_scores[item1_id] or 0
          local item2_score = frecency_scores[item2_id] or 0
          return item1_score > item2_score
        end
      )

      if not ok then
        Log.error('Failed to sort items: %s', vim.inspect(sorted))
      else
        items = sorted
      end

      self.items = items
      return
    else
      Log.debug('Config.sort.frecency is enabled, but sqlite is not availabe, so frecency is automatically disabled.')
    end
  end

  ---@param item1 LegendaryItem
  ---@param item2 LegendaryItem
  local function comparator(item1, item2)
    if item1 == item2 then
      return false
    end

    if opts.most_recent_first then
      if item1 == State.most_recent_item then
        return true
      end
    end

    if opts.user_items_first then
      if not item1.builtin and item2.builtin then
        return true
      end
    end

    if opts.item_type_bias then
      if opts.item_type_bias == 'keymap' then
        return Toolbox.is_keymap(item1) and not Toolbox.is_keymap(item2)
      elseif opts.item_type_bias == 'command' then
        return Toolbox.is_command(item1) and not Toolbox.is_command(item2)
      elseif opts.item_type_bias == 'group' then
        return Toolbox.is_itemgroup(item1) and not Toolbox.is_itemgroup(item2)
      else
        return Toolbox.is_autocmd(item1) and not Toolbox.is_autocmd(item2)
      end
    end
  end

  local ok, sorted = pcall(Sorter.mergesort, items, comparator)
  if not ok then
    Log.error('Failed to sort items: %s', vim.inspect(sorted))
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
