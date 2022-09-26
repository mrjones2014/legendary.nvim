---@mod legendary.filters require('legendary.filters')

require('legendary.types')

local M = {}

--- Return a `LegendaryItemFilter` that filters items
--- by the specified mode
---@param mode string
---@return LegendaryItemFilter
function M.mode(mode: string): LegendaryItemFilter
  return function(item: LegendaryItem): boolean
    -- ignore everything but keymaps since they aren't tied to a mode
    if not string.find(item.kind, 'keymap') then
      return true
    end

    local keymap = item as LegendaryKeymap
    local keymap_mode = keymap.mode or { 'n' }
    if type(keymap_mode) == 'string' then
      keymap_mode = { keymap_mode as string }
    end

    return vim.tbl_contains(keymap_mode as {string}, mode)
  end
end

--- Return a `LegendaryItemFilter` that filters items
--- by the current mode
---@return LegendaryItemFilter
function M.current_mode(): LegendaryItemFilter
  return M.mode((vim.fn.mode() or 'n') as string)
end

return M
