---@type LegendaryConfig
local Config = require('legendary.config')
---@type LegendaryState
local State = require('legendary.data.state')
local Toolbox = require('legendary.toolbox')
local Format = require('legendary.ui.format')
local Executor = require('legendary.api.executor')
local Log = require('legendary.log')

---@class LegendaryUi
---@field select fun(opts:LegendaryFindOpts)
local M = {}

---@class LegendaryFindOpts
---@field filters LegendaryItemFilter[]
---@field select_prompt string|fun():string
---@field formatter LegendaryItemFormatter

---@param opts LegendaryFindOpts
---@param itemlist ItemList
---@param context LegendaryEditorContext
---@overload fun(opts:LegendaryFindOpts,context:LegendaryEditorContext)
local function select_inner(opts, context, itemlist)
  if itemlist then
    Log.trace('Relaunching select UI for an item group')
  else
    Log.trace('Launching select UI')
  end

  itemlist = itemlist or State.items
  opts = opts or {}

  local prompt = opts.select_prompt or Config.select_prompt
  if type(prompt) == 'function' then
    prompt = prompt()
  end

  -- Apply sorting if needed. Note, the internal
  -- implementation of `sort_inplace` checks if
  -- sorting is actually needed and does nothing
  -- if it does not need to be sorted.
  itemlist:sort_inplace()

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

    if Toolbox.is_itemgroup(selected) then
      return select_inner(opts, context, selected.items)
    end

    Log.trace('Preparing to execute selected item')
    State.most_recent_item = selected
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
