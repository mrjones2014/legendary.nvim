local ItemList = require('legendary.data.itemlist')

---@class LegendaryState
---@field items ItemList
local M = {}

M.items = ItemList:create()

return M
