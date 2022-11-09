local class = require('legendary.vendor.middleclass')
local util = require('legendary.util')

---@class Function
---@field implementation function
---@field description string
---@field opts table
---@field class Function
local Function = class('Function')

function Function:parse(tbl) -- luacheck: no unused
  vim.validate({
    ['1'] = { tbl[1], { 'function' } },
    description = { util.get_desc(tbl), { 'string' } },
    opts = { tbl.opts, { 'table' }, true },
  })

  local instance = Function()

  instance.implementation = tbl[1]
  instance.description = util.get_desc(tbl)
  instance.opts = tbl.opts or {}

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

return Function
