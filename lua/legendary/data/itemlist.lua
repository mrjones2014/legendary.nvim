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

ItemList.TOPLEVEL_LIST_ID = 'toplevel'

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
        self.itemgroup_refs[item:id()] = item
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

---Get an ItemGroup by ID/name.
---@param id string
---@return ItemGroup|nil
function ItemList:get_item_group(id)
  if not id or type(id) ~= 'string' or #id == 0 then
    return nil
  end

  return self.itemgroup_refs[id]
end

---@alias LegendaryItemFilter fun(item:LegendaryItem, context: LegendaryEditorContext):boolean

---Filter the ItemList. Returns a *new* ItemList,
---self remains immutable.
---@param filters LegendaryItemFilter|LegendaryItemFilter[]
---@param context LegendaryEditorContext
---@return LegendaryItem[]
function ItemList:filter(filters, context)
  -- wrap in list to make following code more succinct
  if type(filters) ~= 'table' then
    filters = { filters }
  end

  return util.log_performance(function()
    return vim.tbl_filter(function(item)
      -- NOTE: The creation of a new list via vim.list_extend is important here,
      -- otherwise the list gets added to for every item we filter
      local all_filters = vim.list_extend({}, filters, 1, #filters)
      if item.filters then
        all_filters = vim.list_extend(all_filters, item.filters, 1, #item.filters)
      end

      return util.tbl_all(all_filters, function(filter)
        return filter(item, context)
      end)
    end, self.items)
  end, 'Took %s ms to filter items in context.')
end

---@class ItemListSortInplaceOpts
---@field itemgroup string

---Sort the list *IN PLACE* according to config.
---THIS MODIFIES THE LIST IN PLACE.
--- @param opts ItemListSortInplaceOpts
function ItemList:sort_inplace(opts)
  -- inline require to avoid circular dependency
  local State = require('legendary.data.state')
  vim.validate({
    itemgroup = { opts.itemgroup, 'string', true },
  })

  -- Merge Config into local opts
  opts = vim.tbl_extend('keep', opts, Config.sort)

  -- if no items have been added, and the most recent item has not changed,
  -- we're already sorted
  if
    self.sorted
    and (
      not opts.most_recent_first
      or (self.items[1] == State.itemgroup_history[opts.itemgroup or ItemList.TOPLEVEL_LIST_ID])
    )
  then
    return
  end

  -- check if all sort options are false/nil, if so we don't need to do anything
  if not opts.most_recent_first and not opts.user_items_first and opts.item_type_bias == nil then
    return
  end

  local items = self.items

  if Config.sort.frecency ~= false then
    if require('legendary.api.db').is_supported() then
      -- inline require because this module requires sqlite and is a bit heavier
      local DbClient = require('legendary.api.db.client').get_client()
      -- if bootstrapping fails, bail
      if not require('legendary.api.db').is_supported() then
        Log.debug(
          'Config.sort.frecency is enabled, but sqlite is not available or database could not be opened, '
            .. 'frecency is automatically disabled.'
        )
        return
      end
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
      Log.debug(
        'Config.sort.frecency is enabled, but sqlite is not available or database could not be opened, '
          .. 'frecency is automatically disabled.'
      )
    end
  end

  ---@param item1 LegendaryItem
  ---@param item2 LegendaryItem
  local function comparator(item1, item2)
    if item1 == item2 then
      return false
    end

    if opts.most_recent_first then
      if item1 == State.itemgroup_history[opts.itemgroup or ItemList.TOPLEVEL_LIST_ID] then
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
  if
    opts.most_recent_first and State.itemgroup_history[opts.itemgroup or ItemList.TOPLEVEL_LIST_ID] ~= self.items[1]
  then
    items = Sorter.mergesort(items, function(item)
      return item == State.itemgroup_history[opts.itemgroup or ItemList.TOPLEVEL_LIST_ID]
    end)
  end

  self.items = items
end

---Call `callback` on each item
---@param callback fun(item:LegendaryItem)
function ItemList:iter(callback)
  vim.tbl_map(callback, self.items)
end

return ItemList
