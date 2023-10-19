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

return Function
