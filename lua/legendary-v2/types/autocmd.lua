local class = require('legendary-v2.middleclass')
local Id = require('legendary-v2.id')
local util = require('legendary-v2.util')

---@class Autocmd
---@field events string[]
---@field implementation string|fun()
---@field opts table
---@field id integer
---@field description string
---@field group string|integer|nil
---@field kind 'legendary.autocmd'
local Autocmd = class('Autocmd')

---Parse a new autocmd table
---@param tbl table
---@return Autocmd
function Autocmd:parse(tbl) -- luacheck: no unused
  vim.validate({
    ['1'] = { tbl[1], { 'string', 'table' } },
    ['2'] = { tbl[2], { 'string', 'function' } },
    description = { util.get_desc(tbl), { 'string' }, true },
    opts = { tbl.opts, { 'table' }, true },
    group = { tbl.group, { 'string', 'number' }, true },
  })

  local instance = Autocmd()

  -- if tbl[1] is a string, convert to a list with 1 string in it
  instance.events = type(tbl[1]) == 'string' and { tbl[1] } or tbl[1]
  instance.implementation = tbl[2]
  instance.opts = tbl.opts
  instance.description = util.get_desc(tbl)
  instance.group = tbl.group
  instance.id = Id.new()
  instance.kind = 'legendary.autocmd'

  return instance
end

function Autocmd:apply()
  local opts = vim.tbl_deep_extend('keep', {
    callback = type(self.implementation) == 'function' and self.implementation or nil,
    command = type(self.implementation) == 'string' and self.implementation or nil,
  }, self.opts)
  vim.api.nvim_create_autocmd(self.events, opts)
  return self
end

function Autocmd:with_group(group)
  self.group = group
  return self
end

return Autocmd
