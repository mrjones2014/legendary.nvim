local class = require('legendary.vendor.middleclass')
local Autocmd = require('legendary.data.autocmd')
local util = require('legendary.util')

---@class Augroup
---@field name string
---@field clear boolean|nil
---@field autocmds Autocmd
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
  instance.autocmds = {}
  for _, autocmd in ipairs(tbl) do
    table.insert(instance.autocmds, Autocmd:parse(autocmd))
  end

  return instance
end

---Apply the augroup, creating *both the group and it's autocmds*
---@return Augroup
function Augroup:apply()
  local group = vim.api.nvim_create_augroup(self.name, { clear = self.clear })

  for _, autocmd in ipairs(self.autocmds) do
    autocmd:with_group(group):apply()
  end

  return self
end

function Augroup:id()
  return string.format('%s %s', self.name, self.clear)
end

return Augroup
