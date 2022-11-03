local class = require('legendary.api.middleclass')
local util = require('legendary.util')

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
---@field class Command
local Command = class('Command')

---Parse a new command table
---@param tbl table
---@return Command
function Command:parse(tbl) -- luacheck: no unused
  vim.validate({
    ['1'] = { tbl[1], { 'string' } },
    ['2'] = { tbl[2], { 'string', 'function' }, true },
    opts = { tbl.opts, { 'table' }, true },
    description = { util.get_desc(tbl), { 'string' }, true },
    unfinished = { tbl.unfinished, { 'boolean' }, true },
  })

  local instance = Command()

  instance.cmd = tbl[1]
  instance.implementation = tbl[2]
  instance.description = util.get_desc(tbl)
  instance.opts = tbl.opts
  instance.unfinished = util.bool_default(tbl.unfinished, false)

  return instance
end

---Create the user command
---@return Command
function Command:apply()
  if not self.implementation then
    return self
  end

  local opts = vim.deepcopy(self.opts or {})
  opts.desc = opts.desc or self.description
  -- these are valid legendary.nvim options but
  -- are only used for filtering and aren't used
  -- for the actual command mapping
  opts.buffer = nil

  vim.api.nvim_create_user_command(self:vim_cmd(), self.implementation, opts)
  return self
end

function Command:id()
  return string.format('%s %s', self.cmd, self.description)
end

---Return self.cmd with leading : or <cmd> and trailing <cr> removed
function Command:vim_cmd()
  -- replace any argument placeholders for display purposes wrapped in {} or []
  -- % is escape character in gsub patterns
  -- strip param names between [] or {}
  return sanitize_cmd_name(self.cmd)
end

return Command
