---@type LegendaryConfig
local Config = require('legendary.config')
---@type LegendaryState
local State = require('legendary.data.state')
local Format = require('legendary.ui.format')
local Executor = require('legendary.api.executor')

---@class LegendaryUi
---@field select fun(opts:LegendaryFindOpts)
local M = {}

---@class LegendaryFindOpts
---@field filters LegendaryItemFilter[]
---@field select_prompt string|fun():string
---@field formatter LegendaryItemFormatter

---Select an item
---@param opts LegendaryFindOpts
function M.select(opts)
  opts = opts or {}
  local prompt = opts.select_prompt or Config.select_prompt
  if type(prompt) == 'function' then
    prompt = prompt()
  end

  local context = Executor.build_pre_context()

  -- in addition to user filters, we also need to filter by buf
  local items = vim.tbl_filter(function(item)
    local item_buf = vim.tbl_get(item, 'opts', 'buffer')
    return item_buf == nil or item_buf == context.buf
  end, State.items:filter(opts.filters or {}))

  local padding = Format.compute_padding(items, opts.formatter or Config.default_item_formatter, context.mode)

  vim.ui.select(items, {
    prompt = prompt,
    format_item = function(item)
      return Format.format_item(item, opts.formatter or Config.default_item_formatter, padding, context.mode)
    end,
  }, function(selected)
    if not selected then
      return
    end

    if Config.most_recent_items_at_top then
      State.items:sort_inplace_by_recent(selected)
    end

    Executor.exec_item(selected, context)
  end)
end

return M
