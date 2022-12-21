local class = require('legendary.vendor.middleclass')
local util = require('legendary.util')
local Config = require('legendary.config')

---@class ModeKeymapOpts
---@field implementation string|fun()
---@field opts table|nil

---@class ModeKeymap
---@field n ModeKeymapOpts
---@field v ModeKeymapOpts
---@field x ModeKeymapOpts
---@field c ModeKeymapOpts
---@field s ModeKeymapOpts
---@field t ModeKeymapOpts
---@field i ModeKeymapOpts
---@field o ModeKeymapOpts
---@field l ModeKeymapOpts

---@class Keymap
---@field keys string
---@field mode_mappings ModeKeymap
---@field description string
---@field hide boolean
---@field opts table
---@field builtin boolean
---@field class Keymap
local Keymap = class('Keymap')

---Parse a new keymap table
---@param tbl table
---@param builtin boolean Whether the item is a builtin, defaults to false
---@overload fun(tbl:table):Keymap
---@return Keymap
function Keymap:parse(tbl, builtin) -- luacheck: no unused
  vim.validate({
    ['1'] = { tbl[1], { 'string' } },
    ['2'] = { tbl[2], { 'string', 'function', 'table' }, true },
    mode = { tbl.mode, { 'string', 'table' }, true },
    opts = { tbl.opts, { 'table' }, true },
    hide = { tbl.hide, { 'boolean' }, true },
    description = { util.get_desc(tbl), { 'string' }, true },
  })

  if type(tbl[2]) == 'table' then
    vim.validate({
      n = { tbl[2].n, { 'string', 'function', 'table' }, true },
      v = { tbl[2].v, { 'string', 'function', 'table' }, true },
      x = { tbl[2].x, { 'string', 'function', 'table' }, true },
      c = { tbl[2].c, { 'string', 'function', 'table' }, true },
      s = { tbl[2].s, { 'string', 'function', 'table' }, true },
      t = { tbl[2].t, { 'string', 'function', 'table' }, true },
      i = { tbl[2].i, { 'string', 'function', 'table' }, true },
      o = { tbl[2].i, { 'string', 'function', 'table' }, true },
      l = { tbl[2].i, { 'string', 'function', 'table' }, true },
    })
  end

  local instance = Keymap()

  instance.keys = tbl[1]
  instance.hide = util.bool_default(tbl.hide, false)
  instance.description = util.get_desc(tbl)
  instance.opts = tbl.opts or {}
  instance.builtin = builtin or false

  instance.mode_mappings = {}
  if tbl[2] == nil then
    -- for description-only keymaps, just set mode_mappings to the list of modes
    instance.mode_mappings = tbl.mode or { 'n' }
    if type(instance.mode_mappings) == 'string' then
      instance.mode_mappings = { instance.mode_mappings }
    end

    if #instance.mode_mappings == 0 then
      instance.mode_mappings = { 'n' }
    end

    return instance
  end

  if type(tbl[2]) == 'table' then
    for mode, mapping in pairs(tbl[2]) do
      if type(mapping) == 'table' then
        instance.mode_mappings[mode] = { implementation = mapping[1], opts = mapping.opts }
      else
        instance.mode_mappings[mode] = { implementation = mapping }
      end
    end
  else
    if type(tbl.mode) == 'table' then
      for _, mode in ipairs(tbl.mode) do
        instance.mode_mappings[mode] = { implementation = tbl[2] }
      end
    else
      instance.mode_mappings[tbl.mode or 'n'] = { implementation = tbl[2] }
    end
  end

  return instance
end

---Bind the keymap in Neovim
---@return Keymap
function Keymap:apply()
  if vim.tbl_islist(self.mode_mappings) then
    -- description-only keymap
    return self
  end

  for mode, mapping in pairs(self.mode_mappings) do
    local opts = vim.tbl_deep_extend('keep', mapping.opts or {}, self.opts or {})
    opts = vim.tbl_deep_extend('keep', opts, Config.default_opts.keymaps or {})
    opts.desc = opts.desc or self.description
    vim.keymap.set(mode, self.keys, mapping.implementation, opts)
  end

  return self
end

function Keymap:id()
  return string.format('%s %s %s', self.keys, table.concat(self:modes(), ','), self.description)
end

function Keymap:frecency_id()
  return string.format('%s', self.description)
end

function Keymap:modes()
  if vim.tbl_islist(self.mode_mappings) then
    return self.mode_mappings
  end

  local modes = {}
  for mode, mapping in pairs(self.mode_mappings) do
    if mapping then
      table.insert(modes, mode)
    end
  end

  if #modes == 0 then
    return { 'n' }
  end

  return modes
end

---Parse a vimscript keymapping command (e.g. `vmap <silent> <leader>f :SomeCommand<CR>`)
---into a Keymap
---@param vimscript_str string
---@param description string keymap description
---@return Keymap,table
function Keymap:from_vimscript(vimscript_str, description) -- luacheck: no unused
  local ok, cmd_info = pcall(vim.api.nvim_parse_cmd, vimscript_str, {})
  if not ok then
    error(string.format('[legendary.nvim] Error parsing vimscript keymap: %s', cmd_info))
  end

  local opts = {}
  local idx_of_keys = 0
  for _, arg in ipairs(cmd_info.args) do
    idx_of_keys = idx_of_keys + 1
    local lower = arg:lower()
    if lower == '<buffer>' then
      opts.buffer = vim.api.nvim_get_current_buf()
    elseif lower == '<nowait>' then
      opts.nowait = true
    elseif lower == '<silent>' then
      opts.silent = true
    elseif lower == '<script>' then -- luacheck: ignore
      -- I don't think we can handle this one
    elseif lower == '<expr>' then
      opts.expr = true
    elseif lower == '<unique>' then
      opts.unique = true
    else
      break
    end
  end

  local keys = cmd_info.args[idx_of_keys]

  local cmd = cmd_info.cmd:lower()
  local cmd_first_char = cmd:sub(1, 1)
  local mode
  if cmd ~= 'map' and cmd ~= 'noremap' then
    mode = { cmd_first_char }
    if vim.startswith(cmd, string.format('%sno', cmd_first_char)) then
      opts.remap = false
    else
      opts.remap = true
    end
  elseif cmd_info.bang then
    mode = { 'i', 'c' }
    if cmd == 'noremap' then
      opts.remap = false
    else
      opts.remap = true
    end
  else
    mode = { 'n', 'v', 's', 'o' }
    if cmd == 'noremap' then
      opts.remap = false
    else
      opts.remap = true
    end
  end

  local rhs = vim.trim(table.concat(vim.list_slice(cmd_info.args, idx_of_keys + 1, #cmd_info.args)))
  local input = { keys, rhs, description = description, opts = opts, mode = mode }
  return Keymap:parse(input), input
end

return Keymap
