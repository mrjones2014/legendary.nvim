---@type LegendaryConfig
local Config = require('legendary.config')
---@type LegendaryState
local State = require('legendary.data.state')
local Toolbox = require('legendary.toolbox')
local Format = require('legendary.ui.format')
local Executor = require('legendary.api.executor')
local Log = require('legendary.log')
local ItemList = require('legendary.data.itemlist')

---@class LegendaryUi
---@field select fun(opts:LegendaryFindOpts)
local M = {}

---@class LegendaryFindOpts : ItemListSortInplaceOpts
---@field itemgroup string Find items in this item group only
---@field filters LegendaryItemFilter[]
---@field select_prompt string|fun():string
---@field formatter LegendaryItemFormatter

---@param opts LegendaryFindOpts
---@param itemlist ItemList
---@param context LegendaryEditorContext
---@overload fun(opts:LegendaryFindOpts,context:LegendaryEditorContext)
local function select_inner(opts, context, itemlist)
  opts = opts or {}

  vim.validate({
    itemgroup = { opts.itemgroup, 'string', true },
    select_prompt = { opts.select_prompt, { 'string', 'function' }, true },
  })

  if itemlist then
    Log.trace('Launching select UI')
  elseif opts.itemgroup then
    Log.trace('Relaunching select UI for an item group')
    -- if no itemlist passed, try to use itemgroup
    -- if an item group id is specified, use that
    local itemgroup = State.items:get_item_group(opts.itemgroup)
    if itemgroup then
      itemlist = itemgroup.items
    else
      Log.error('Expected itemlist, got %s.\n    %s', type(itemlist), vim.inspect(itemlist))
    end
  else
    itemlist = State.items
  end

  local prompt = opts.select_prompt or Config.select_prompt
  if type(prompt) == 'function' then
    prompt = prompt()
  end

  -- Apply sorting if needed. Note, the internal
  -- implementation of `sort_inplace` checks if
  -- sorting is actually needed and does nothing
  -- if it does not need to be sorted.
  itemlist:sort_inplace(opts)

  local filters = opts.filters or {}
  if type(filters) ~= 'table' then
    ---@diagnostic disable-next-line
    filters = { filters }
  end

  -- in addition to user filters, we also need to filter by buf
  table.insert(filters, 1, function(item, local_context)
    local item_buf = vim.tbl_get(item, 'opts', 'buffer')
    return item_buf == nil or item_buf == local_context.buf
  end)

  State.most_recent_filters = filters

  local items = itemlist:filter(filters, context)
  local padding = Format.compute_padding(items, opts.formatter or Config.default_item_formatter, context.mode)

  vim.ui.select(items, {
    prompt = prompt,
    kind = 'legendary.nvim',
    format_item = function(item)
      return Format.format_item(item, opts.formatter or Config.default_item_formatter, padding, context.mode)
    end,
  }, function(selected)
    if not selected then
      return
    end

    State.itemgroup_history[opts.itemgroup or ItemList.TOPLEVEL_LIST_ID] = selected

    if Toolbox.is_itemgroup(selected) then
      local item_group_id = selected:id()

      local opts_next = vim.tbl_extend('force', opts, {
        itemgroup = item_group_id,
      })

      return select_inner(opts_next, context)
    end

    Log.trace('Preparing to execute selected item')
    Executor.exec_item(selected, context)
  end)
end

---Select an item
---@param opts LegendaryFindOpts
function M.select(opts)
  vim.cmd('doautocmd User LegendaryUiPre')
  local context = Executor.build_context()
  select_inner(opts, context)
end

return M
