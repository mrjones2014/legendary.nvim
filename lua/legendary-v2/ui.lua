local Config = require('legendary-v2.config')
local State = require('legendary-v2.state')
local M = {}

---@class LegendaryFindOpts
---@field filters ItemFilter[]
---@field prompt string|fun():string

---Select an item
---@param opts LegendaryFindOpts
---@param callback fun(item:LegendaryItem)
function M.select(opts, callback)
  opts = opts or {}
  local items = State.items:filter(opts.filters or {})
  local prompt = opts.prompt or Config.select_prompt
  if type(prompt) == 'function' then
    prompt = prompt()
  end

  vim.ui.select(items, {
    prompt = prompt,
    format_item = function(item)
      -- TODO
      return item.description
    end,
  }, callback)
end

return M
