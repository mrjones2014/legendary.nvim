local ItemList = require('legendary.data.itemlist')

---@class LegendaryState
---@field items ItemList
---@field most_recent_item LegendaryItem|nil
local M = {}

M.items = ItemList:create()
M.most_recent_item = nil

return M
