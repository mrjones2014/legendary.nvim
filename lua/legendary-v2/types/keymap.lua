local class = require('legendary-v2.middleclass')
local Id = require('legendary-v2.id')
local util = require('legendary-v2.util')

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

---@class Keymap
---@field keys string
---@field mode_mappings ModeKeymap
---@field description string
---@field kind 'legendary.keymap'
---@field opts table
---@field id integer
local Keymap = class('Keymap')

---Parse a keymap
---@param tbl table
---@return Keymap
function Keymap:parse(tbl)
  vim.validate({
    ['1'] = { tbl[1], { 'string' } },
    ['2'] = { tbl[2], { 'string', 'function', 'table' }, true },
    mode = { tbl.mode, { 'string', 'table' }, true },
    opts = { tbl.opts, { 'table' }, true },
    description = { util.get_desc(tbl), { 'string' }, true },
  })

  if type(tbl[2]) == 'table' then
    vim.validate({
      n = { tbl[2].n, { 'string', 'function', 'table' }, true },
      v = { tbl[2].n, { 'string', 'function', 'table' }, true },
      x = { tbl[2].n, { 'string', 'function', 'table' }, true },
      c = { tbl[2].n, { 'string', 'function', 'table' }, true },
      s = { tbl[2].n, { 'string', 'function', 'table' }, true },
      t = { tbl[2].n, { 'string', 'function', 'table' }, true },
      i = { tbl[2].n, { 'string', 'function', 'table' }, true },
    })
  end

  self.keys = tbl[1]
  self.description = util.get_desc(tbl)
  self.kind = 'legendary.keymap'
  self.opts = tbl.opts or {}
  self.id = Id.new()

  self.mode_mappings = {}
  if tbl[2] == nil then
    return self
  end

  if type(tbl[2]) == 'table' then
    for mode, mapping in pairs(tbl[2]) do
      if type(mapping) == 'table' then
        self.mode_mappings[mode] = { implementation = mapping[1], opts = mapping.opts }
      else
        self.mode_mappings[mode] = { implementation = mapping }
      end
    end
  else
    if type(tbl.mode) == 'table' then
      for _, mode in ipairs(tbl.mode) do
        self.mode_mappings[mode] = { implementation = tbl[2] }
      end
    else
      self.mode_mappings[tbl.mode or 'n'] = { implementation = tbl[2] }
    end
  end

  return self
end

---Bind the keymap in Neovim
---@return Keymap
function Keymap:apply()
  for mode, mapping in pairs(self.mode_mappings) do
    local opts = vim.tbl_deep_extend('keep', mapping.opts or {}, self.opts or {})
    opts.desc = opts.desc or self.description
    vim.keymap.set(mode, self.keys, mapping.implementation, opts)
  end

  return self
end

return Keymap
