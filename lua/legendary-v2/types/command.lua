local class = require('legendary-v2.middleclass')
local Id = require('legendary-v2.id')
local util = require('legendary-v2.util')

---@class Command
---@field cmd string
---@field implementation string|function|nil
---@field description string
---@field opts table
---@field unfinished boolean
---@field id integer
local Command = class('Command')

function Command:parse(tbl)
  vim.validate({
    ['1'] = { tbl[1], { 'string' } },
    ['2'] = { tbl[2], { 'string', 'function' }, true },
    opts = { tbl.opts, { 'table' }, true },
    description = { util.get_desc(tbl), { 'string' }, true },
    unfinished = { tbl.unfinished, { 'boolean' }, true },
  })

  self.cmd = tbl[1]
  self.implementation = tbl[2]
  self.description = util.get_desc(tbl)
  self.opts = tbl.opts
  if tbl.unfinished == nil then
    self.unfinished = false
  else
    self.unfinished = tbl.unfinished
  end
  self.id = Id.new()

  return self
end

function Command:apply()
  if not self.implementation then
    return
  end

  local opts = vim.deepcopy(self.opts or {})
  opts.desc = opts.desc or self.description
  vim.api.nvim_create_user_command(self.cmd, self.implementation, opts)
end
