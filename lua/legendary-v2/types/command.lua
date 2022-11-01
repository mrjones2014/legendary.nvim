local class = require('legendary-v2.middleclass')
local Id = require('legendary-v2.id')
local util = require('legendary-v2.util')

local function sanitize_cmd_name(cmd_orig)
  local cmd = (cmd_orig .. ''):gsub('{.*}$', ''):gsub('%[.*%]$', '')
  if vim.startswith(cmd:lower(), '<cmd>') then
    cmd = cmd:sub(6)
  elseif vim.startswith(cmd, ':') then
    cmd = cmd:sub(2)
  end

  if vim.endswith(cmd:lower(), '<cr>') then
    cmd = cmd:sub(1, #cmd - 4)
  elseif vim.endswith(cmd, '\r') then
    cmd = cmd:sub(1, #cmd - 2)
  end

  return vim.trim(cmd)
end

---@class Command
---@field cmd string
---@field implementation string|function|nil
---@field description string
---@field opts table
---@field unfinished boolean
---@field id integer
local Command = class('Command')

---Parse a command table
---@param tbl table
---@return Command
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

---Create the user command
---@return Command
function Command:apply()
  if not self.implementation then
    return self
  end

  local opts = vim.deepcopy(self.opts or {})
  opts.desc = opts.desc or self.description

  -- replace any argument placeholders for display purposes wrapped in {} or []
  -- % is escape character in gsub patterns
  -- strip param names between [] or {}
  vim.api.nvim_create_user_command(sanitize_cmd_name(self.cmd), self.implementation, opts)
  return self
end

return Command
