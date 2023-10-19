local class = require('legendary.vendor.middleclass')
local util = require('legendary.util')
local Filters = require('legendary.data.filters')

---Check if modes is an array of strings or itself a string
---@param modes table
---@return boolean
local is_list_of_strings_or_string = function(modes)
  if modes == nil or type(modes) == 'string' then
    return true
  end
  for _, mode in ipairs(modes) do
    if type(mode) ~= 'string' then
      return false
    end
  end
  return true
end

---@class Function
---@field implementation function
---@field mode_mappings string[]
---@field description string
---@field opts table
---@field filters (function[])|nil
---@field frecency_id fun(self):string
---@field class Function
local Function = class('Function')
Function:include(Filters) ---@diagnostic disable-line

function Function:parse(tbl) -- luacheck: no unused
  vim.validate({
    ['1'] = { tbl[1], { 'function' } },
    mode = {
      tbl.mode,
      is_list_of_strings_or_string,
      'item.mode should contain only strings of modes: n, i, v etc.',
    },
    description = { util.get_desc(tbl), { 'string' } },
    opts = { tbl.opts, { 'table' }, true },
  })

  local instance = Function()

  instance.implementation = tbl[1]
  instance.description = util.get_desc(tbl)
  instance.opts = tbl.opts or {}
  instance:parse_filters(tbl.filters)

  -- By default, function can be run in all modes, so mode_mapping is empty
  instance.mode_mappings = vim.tbl_islist(tbl.mode) and tbl.mode or {}

  -- If tbl = { fn, mode = "n" }
  if type(tbl.mode) == 'string' then
    table.insert(instance.mode_mappings, tbl.mode)
  end
  -- only tbl = { fn, mode = { 'n' } }
  -- Reassing implementation with a current-mode hanlder
  if not vim.tbl_isempty(instance.mode_mappings) then
    local impl = instance.implementation
    instance.implementation = function()
      local modeCurrent = vim.fn.mode()
      for _, modeInstance in ipairs(instance.mode_mappings) do
        if modeCurrent == modeInstance then
          impl()
        end
      end
    end
  end
  -- mode_mapping is going to remain static during legendary runtime
  -- so we can cache current mapping state
  instance._mode_switched = vim.tbl_islist(instance.mode_mappings) and not vim.tbl_isempty(instance.mode_mappings)
  return instance
end

function Function:apply() -- luacheck: no unused
  -- no-op, just for the sake of keeping the same interface
  -- between item types
  return self
end

function Function:id()
  return string.format('<function> %s %s', self.description, vim.inspect(self.opts or {}))
end

function Function:frecency_id()
  return string.format('<function> %s', self.description)
end

--- Intended to be used by UI filters
function Function:modeSwitched()
  return self._mode_switched
end

function Function:modes()
  if self:modeSwitched() then
    return self.mode_mappings
  else
    -- Just use all modes for UI filtering
    -- it's half-assed because UI filtering is ugly ¯\_(ツ)_/¯
    return { 'n', 'V', 'v', 'x', 's', 'o', '' }
  end
end

return Function
