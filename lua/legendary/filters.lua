---@mod legendary.filters

local Toolbox = require('legendary.toolbox')

local M = {}

--- Return a `LegendaryItemFilter` that filters items
--- by the specified mode
---@param mode string
---@return LegendaryItemFilter
function M.mode(mode)
  return function(item)
    -- include everything that isn't a keymap since they aren't tied to a mode
    if not Toolbox.is_keymap(item) then
      return true
    end

    -- map mode equivalencies
    local filter_modes = { mode }
    if mode == 'v' then
      filter_modes = { 'v', 'x', 's' }
    elseif mode == 's' then
      filter_modes = { 'v', 's' }
    elseif mode == 'l' then
      filter_modes = { 'l', 'i', 'c' }
    end

    -- filter where any filter_modes match any item:modes()
    return #vim.tbl_filter(function(keymap_mode)
      return #vim.tbl_filter(function(filter_mode)
        return filter_mode == keymap_mode
      end, filter_modes) > 0
    end, item:modes()) > 0
  end
end

---Logical AND the given LegendaryItemFilters
---@param ... LegendaryItemFilter
---@return LegendaryItemFilter
function M.AND(...)
  local filters = { ... }
  return function(item)
    for _, filter in ipairs(filters) do
      if not filter(item) then
        return false
      end
    end

    return true
  end
end

---Logical OR the given LegendaryItemFilters
---@param ... LegendaryItemFilter
---@return LegendaryItemFilter
function M.OR(...)
  local filters = { ... }
  return function(item)
    for _, filter in ipairs(filters) do
      if filter(item) then
        return true
      end
    end

    return false
  end
end

--- Return a `LegendaryItemFilter` that filters items
--- by the current mode
---@return LegendaryItemFilter
function M.current_mode()
  return M.mode((vim.fn.mode() or 'n'))
end

---Filter to only show keymaps
---@return LegendaryItemFilter
function M.keymaps()
  return M.OR(Toolbox.is_keymap, Toolbox.is_itemgroup)
end

---Filter to only show commands
---@return LegendaryItemFilter
function M.commands()
  return M.OR(Toolbox.is_command, Toolbox.is_itemgroup)
end

---Filter to only show autocmds
---@return LegendaryItemFilter
function M.autocmds()
  return M.OR(Toolbox.is_autocmd, Toolbox.is_itemgroup)
end

---Filter to only show functions
---@return LegendaryItemFilter
function M.funcs()
  return M.OR(Toolbox.is_function, Toolbox.is_itemgroup)
end

return M
