local class = require('legendary.vendor.middleclass')
local util = require('legendary.util')
local Config = require('legendary.config')
local Toolbox = require('legendary.toolbox')

---@class ModeCommand
---@field n string|fun()|nil
---@field v string|fun()|nil
---@field x string|fun()|nil
---@field c string|fun()|nil
---@field s string|fun()|nil
---@field t string|fun()|nil
---@field i string|fun()|nil
---@field o string|fun()|nil
---@field l string|fun()|nil

---@class Command
---@field cmd string
---@field implementation string|function|ModeCommand|nil
---@field description string
---@field opts table
---@field unfinished boolean
---@field builtin boolean
---@field class Command
local Command = class('Command')

local function exec(impl, args)
  if type(impl) == 'string' then
    if vim.startswith(impl, ':') or vim.startswith(impl:lower(), '<cmd>') then
      vim.cmd(util.sanitize_cmd_str(impl))
    else
      util.exec_feedkeys(impl)
    end
  elseif type(impl) == 'function' then
    impl(args)
  end
end

local function parse_modemap(map)
  return function(args)
    local mode = vim.fn.mode()
    local impl = map[mode]
    if not impl then
      if Toolbox.is_visual_mode(mode) then
        impl = impl or map.v or map.x
      elseif mode == 'i' then
        impl = impl or map.l
      elseif mode == 'c' then
        impl = impl or map.l
      elseif mode == 's' then
        impl = impl or map.s or map.v
      end
    end

    if impl then
      exec(impl, args)
    end
  end
end

---Parse a new command table
---@param tbl table
---@param builtin boolean Whether the item is a builtin, defaults to false
---@overload fun(tbl:table):Command
---@return Command
function Command:parse(tbl, builtin) -- luacheck: no unused
  vim.validate({
    ['1'] = { tbl[1], { 'string' } },
    ['2'] = { tbl[2], { 'string', 'function', 'table' }, true },
    opts = { tbl.opts, { 'table' }, true },
    description = { util.get_desc(tbl), { 'string' }, true },
    unfinished = { tbl.unfinished, { 'boolean' }, true },
  })

  local instance = Command()

  instance.cmd = tbl[1]
  instance.description = util.get_desc(tbl)
  instance.opts = tbl.opts
  instance.unfinished = util.bool_default(tbl.unfinished, false)
  instance.implementation = tbl[2]
  instance.builtin = builtin or false

  if type(instance.implementation) == 'table' then
    vim.validate({
      n = { tbl[2].n, { 'string', 'function' }, true },
      v = { tbl[2].v, { 'string', 'function' }, true },
      x = { tbl[2].x, { 'string', 'function' }, true },
      c = { tbl[2].c, { 'string', 'function' }, true },
      s = { tbl[2].s, { 'string', 'function' }, true },
      t = { tbl[2].t, { 'string', 'function' }, true },
      i = { tbl[2].i, { 'string', 'function' }, true },
      o = { tbl[2].i, { 'string', 'function' }, true },
      l = { tbl[2].i, { 'string', 'function' }, true },
    })

    instance.implementation = parse_modemap(instance.implementation)
  end

  return instance
end

---Create the user command
---@return Command
function Command:apply()
  if not self.implementation then
    return self
  end

  local opts = vim.deepcopy(self.opts or {})
  opts = vim.tbl_deep_extend('keep', opts, Config.default_opts.commands or {})
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
  return util.sanitize_cmd_str(self.cmd)
end

return Command
