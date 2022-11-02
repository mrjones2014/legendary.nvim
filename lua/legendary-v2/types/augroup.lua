local class = require('legendary-v2.middleclass')
local Id = require('legendary-v2.id')
local Autocmd = require('legendary-v2.types.autocmd')
local util = require('legendary-v2.util')

---@class Augroup : Autocmd[]
---@field name string
---@field clear boolean|nil
---@field id integer
---@field kind 'legendary.augroup'
---@field class Augroup
local Augroup = class('Augroup')

---Parse a new augroup table
---@param tbl Augroup
---@return Augroup
function Augroup:parse(tbl) -- luacheck: no unused
  vim.validate({
    name = { tbl.name, { 'string' } },
    clear = { tbl.clear, { 'boolean' }, true },
  })

  local instance = Augroup()

  instance.name = tbl.name
  instance.clear = util.bool_default(tbl.clear, true)
  instance.id = Id.new()
  instance.kind = 'legendary.augroup'
  for _, autocmd in ipairs(tbl) do
    table.insert(instance, Autocmd:parse(autocmd))
  end

  return instance
end

---Apply the augroup, creating *both the group and it's autocmds*
---@return Augroup
function Augroup:apply()
  local group = vim.api.nvim_create_augroup(self.name, { clear = self.clear })

  for _, autocmd in ipairs(self) do
    autocmd:with_group(group):apply()
  end

  return self
end

return Augroup
