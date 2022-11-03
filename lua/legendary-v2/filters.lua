local Keymap = require('legendary-v2.data.keymap')
local Command = require('legendary-v2.data.command')
local Autocmd = require('legendary-v2.data.autocmd')
local Function = require('legendary-v2.data.function')

local M = {}

--- Return a `LegendaryItemFilter` that filters items
--- by the specified mode
---@param mode string
---@return ItemFilter
function M.mode(mode)
  return function(item)
    -- ignore everything but keymaps since they aren't tied to a mode
    if item.class ~= Keymap then
      return true
    end

    local keymap = item
    local keymap_mode = keymap.mode or { 'n' }
    if type(keymap_mode) == 'string' then
      keymap_mode = { keymap_mode }
    end

    return vim.tbl_contains(keymap_mode, mode)
  end
end

--- Return a `LegendaryItemFilter` that filters items
--- by the current mode
---@return ItemFilter
function M.current_mode()
  return M.mode((vim.fn.mode() or 'n'))
end

---Filter to only show keymaps
---@return ItemFilter
function M.keymaps()
  return function(item)
    return item.class == Keymap
  end
end

---Filter to only show commands
---@return ItemFilter
function M.commands()
  return function(item)
    return item.class == Command
  end
end

---Filter to only show autocmds
---@return ItemFilter
function M.autocmds()
  return function(item)
    return item.class == Autocmd
  end
end

---Filter to only show functions
---@return ItemFilter
function M.funcs()
  return function(item)
    return item.class == Function
  end
end

return M
