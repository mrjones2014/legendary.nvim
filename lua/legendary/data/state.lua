local ItemList = require('legendary.data.itemlist')

---@class LegendaryState
---@field items ItemList
---@field last_executed_item LegendaryItem|nil
---@field most_recent_filters LegendaryItemFilter[]|nil
---@field itemgroup_history table<string, LegendaryItem>
local M = {}

M.items = ItemList:create()
M.last_executed_item = nil
M.most_recent_filters = nil
M.itemgroup_history = {}

return M
