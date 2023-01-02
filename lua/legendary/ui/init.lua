---@type LegendaryConfig
local Config = require('legendary.config')
---@type LegendaryState
local State = require('legendary.data.state')
local Toolbox = require('legendary.toolbox')
local Format = require('legendary.ui.format')
local Executor = require('legendary.api.executor')
local Log = require('legendary.log')

local function update_item_frecency_score(item)
  if Config.sort.frecency ~= false then
    local has_sqlite, _ = pcall(require, 'sqlite')
    if has_sqlite then
      Log.trace('Updating scoring data for selected item.')
      local DbClient = require('legendary.api.db.client').init()
      DbClient.update_item_score(item)
    else
      Log.debug('Config.sort.frecency is enabled, but sqlite is not availabe, so frecency is automatically disabled.')
    end
  end
end

---@param items ItemList
---@param context LegendaryEditorContext
---@param filters LegendaryItemFilter|LegendaryItemFilter[]
---@return LegendaryItem[]
local function resolve_items(items, context, filters)
  local start_time = vim.loop.hrtime()

  filters = filters or {}
  if type(filters) ~= 'table' then
    filters = { filters }
  end

  -- filter out keymaps and process those separately
  table.insert(filters, function(item)
    return not Toolbox.is_keymap(item)
  end)

  local keymaps = items:filter({
    Toolbox.is_keymap,
    function(item)
      local item_buf = vim.tbl_get(item, 'opts', 'buffer')
      local item_ft = vim.tbl_get(item, 'filetype')
      local item_bt = vim.tbl_get(item, 'buftype')
      local matches_buf = item_buf == nil or item_buf == context.buf
      local matches_ft = item_ft == nil or item_ft == context.ft
      local matches_bt = item_bt == nil or item_bt == context.bt
      return matches_buf and matches_ft and matches_bt
    end,
  }) --[[ @as Keymap[] ]]
  local specificity_map = {}
  for _, keymap in ipairs(keymaps) do
    if not specificity_map[keymap.keys] then
      specificity_map[keymap.keys] = keymap
    else
      local existing = specificity_map[keymap.keys] --[[ @as Keymap ]]
      if keymap.keys == '<leader>qq' then
        print(vim.tbl_islist(keymap))
      end
      -- check buf, filetype, buftype, and builtin
      if
        vim.tbl_get(existing, 'opts', 'buffer') ~= context.buf
        and vim.tbl_get(keymap, 'opts', 'buffer') == context.buf
      then
        specificity_map[keymap.keys] = keymap
      elseif
        vim.tbl_get(existing, 'filetype') ~= context.ft
        and #context.ft > 0
        and vim.tbl_get(keymap, 'filetype') == context.ft
      then
        specificity_map[keymap.keys] = keymap
      elseif
        vim.tbl_get(existing, 'buftype') ~= context.bt
        and #context.bt > 0
        and vim.tbl_get(keymap, 'buftype') == context.bt
      then
        specificity_map[keymap.keys] = keymap
      elseif existing.builtin and not keymap.builtin then
        specificity_map[keymap.keys] = keymap
      end
    end
  end

  local other_items = items:filter(filters)
  local keymap_items = vim.tbl_values(specificity_map)
  local resolved = vim.list_extend(other_items, keymap_items, 1, #keymap_items)
  local duration = vim.loop.hrtime() - start_time
  Log.debug('Took %s ms to resolve %s items in context.', duration / 1000000, #resolved)
  return resolved
end

---@class LegendaryUi
---@field select fun(opts:LegendaryFindOpts)
local M = {}

---@class LegendaryFindOpts
---@field filters LegendaryItemFilter[]
---@field select_prompt string|fun():string
---@field formatter LegendaryItemFormatter

---@param opts LegendaryFindOpts
---@param itemlist ItemList
---@overload fun(opts:LegendaryFindOpts)
local function select_inner(opts, itemlist)
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

  local context = Executor.build_pre_context()

  local items = resolve_items(itemlist, context, opts.filters)
  -- Apply sorting if needed. Note, the internal
  -- implementation of `sort_inplace` checks if
  -- sorting is actually needed and does nothing
  -- if it does not need to be sorted.
  itemlist:sort_inplace()
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

    local ok, err = pcall(update_item_frecency_score, selected)
    if not ok then
      Log.error('Failed to update frecency score: %s', err)
    end

    State.most_recent_item = selected
    if Toolbox.is_itemgroup(selected) then
      return select_inner(opts, selected.items)
    end

    Log.trace('Preparing to execute selected item')
    Executor.exec_item(selected, context)
  end)
end

---Select an item
---@param opts LegendaryFindOpts
function M.select(opts)
  select_inner(opts)
end

return M
