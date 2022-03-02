---@class LegendaryConfig
---@field include_builtin boolean
---@field select_prompt string
---@field keymaps LegendaryItem[]
---@field commands LegendaryItem[]
---@field auto_register_which_key boolean
local LegendaryConfig --luacheck: ignore

---@class LegendaryItem
---@field [1] string
---@field [2] string | function | nil
---@field mode string | string[]
---@field description string
---@field opts table
local LegendaryItem --luacheck: ignore

---@class LegendaryAugroup
---@field name string
---@field clear boolean
---@field [1] LegendaryItem[]
local LegendaryAugroup --luacheck: ignore
