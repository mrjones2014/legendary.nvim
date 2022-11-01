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

---Parse an autocmd table
---@param tbl Autocmd
function Autocmd:parse(tbl)
  vim.validate({
    ['1'] = { tbl[1], { 'string', 'table' } },
    ['2'] = { tbl[2], { 'string', 'function' } },
    description = { util.get_desc(tbl), { 'string' }, true },
    opts = { tbl.opts, { 'table' }, true },
    group = { tbl.group, { 'string', 'number' }, true },
  })

  -- if tbl[1] is a string, convert to a list with 1 string in it
  self.events = type(tbl[1]) == 'string' and { tbl[1] } or tbl[1]
  self.implementation = tbl[2]
  self.opts = tbl.opts
  self.description = util.get_desc(tbl)
  self.group = tbl.group
  self.id = Id.new()
  self.kind = 'legendary.autocmd'

  return self
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
