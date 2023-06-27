local ItemList = require('legendary.data.itemlist')

---@class LegendaryState
---@field items ItemList
---@field most_recent_item LegendaryItem|nil
---@field most_recent_filters LegendaryItemFilter[]|nil
local M = {}

M.items = ItemList:create()
M.most_recent_item = nil
M.most_recent_filters = nil

return M
