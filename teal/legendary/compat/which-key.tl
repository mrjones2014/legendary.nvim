require('legendary.types')
local M = {}

local function wk_to_legendary(wk: table): LegendaryKeymap
  local legendary: table = {}
  legendary[1] = wk.prefix
  if wk.cmd then
    legendary[2] = wk.cmd
  end
  legendary.description = wk.label
  legendary.opts = wk.opts or {}
  return legendary as LegendaryKeymap
end

--- Take which-key.nvim tables
--- and parse them into legendary.nvim tables
---@param which_key_tbls table[]
---@param which_key_opts table
---@return LegendaryItem[]
function M.parse_whichkey(which_key_tbls: {table}, which_key_opts: table): {LegendaryKeymap}
  local wk_parsed = ((_G['require']('which-key.keys') as table).parse_mappings as function(_: table, tbls: {table}, prefix: string): table)(
    {},
    which_key_tbls,
    which_key_opts and (which_key_opts.prefix as string | nil) or ''
  )
  local legendary_tbls: {LegendaryKeymap} = {}
  vim.tbl_map(function(wk: table): nil
    -- check wk.group because these don't represent standalone keymaps
    -- they basically represent a "folder" of other keymaps
    -- TODO support which-key mappings with buf values
    if not wk.label or ((type(wk.group) == 'boolean' and not wk.group) or (#(tostring(wk.group) or '') == 0)) or wk.buf ~= nil then
      goto continue
    end

    table.insert(legendary_tbls, wk_to_legendary(wk))

    ::continue::
  end, wk_parsed)
  return legendary_tbls
end

--- Bind a which-key.nvim table with legendary.nvim
---@param wk_tbls table
---@param wk_opts table
function M.bind_whichkey(wk_tbls: {table}, wk_opts: table)
  local legendary_tbls = M.parse_whichkey(wk_tbls, wk_opts)
  require('legendary.bindings').bind_keymaps(legendary_tbls)
end

--- Enable auto-registering of which-key.nvim tables
--- with legendary.nvim
function M.whichkey_listen(): boolean
  local wk = (_G['require']('which-key') as table)
  local original = wk.register as function(tbls: {table}, opts: table)
  local listener = function(whichkey_tbls: {table}, whichkey_opts: table)
    M.bind_whichkey(whichkey_tbls, whichkey_opts)
    original(whichkey_tbls, whichkey_opts)
  end
  wk.register = listener
  return true
end

return M
