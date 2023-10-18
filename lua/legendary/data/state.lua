local ItemList = require('legendary.data.itemlist')

---@class LegendaryState
---@field items ItemList
---@field most_recent_item LegendaryItem|nil
---@field most_recent_filters LegendaryItemFilter[]|nil
---@field itemgroup_history ItemList[]
local M = {}

M.items = ItemList:create()
M.most_recent_item = nil
M.most_recent_filters = nil
M.itemgroup_history = {}

return M
