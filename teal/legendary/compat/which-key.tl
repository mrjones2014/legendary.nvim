---@mod legendary.compat.which-key require('legendary.compat.which-key')

require('legendary.types')
local M = {}

local function wk_to_legendary(wk: table, wk_opts: table): LegendaryKeymap
  local legendary: table = {}
  legendary[1] = wk.prefix
  if wk.cmd then
    legendary[2] = wk.cmd
  end
  if wk_opts and wk_opts.mode then
    legendary.mode = wk_opts.mode
  end
  legendary.description = wk.label or vim.tbl_get(wk, 'opts', 'desc')
  legendary.opts = wk.opts or {}
  return legendary as LegendaryKeymap
end

--- Take which-key.nvim tables
--- and parse them into legendary.nvim tables
---@param which_key_tbls table[]
---@param which_key_opts table
---@param do_binding boolean whether to bind the keymaps or let which-key handle it
---@return LegendaryItem[]
function M.parse_whichkey(which_key_tbls: {table}, which_key_opts: table, do_binding: boolean): {LegendaryKeymap}
  if do_binding == nil then
    do_binding = true
  end
  local wk_parsed = ((_G['require']('which-key.mappings') as table).parse as function(tbls: {table}, opts: table): table)(
    which_key_tbls,
    which_key_opts
  )
  local legendary_tbls: {LegendaryKeymap} = {}
  vim.tbl_map(function(wk: table): nil
    -- check wk.group because these don't represent standalone keymaps
    -- they basically represent a "folder" of other keymaps
    -- TODO support which-key mappings with buf values
    if not vim.tbl_get(wk, 'opts', 'desc') or wk.group == true then
      goto continue
    end

    table.insert(legendary_tbls, wk_to_legendary(wk, which_key_opts))

    ::continue::
  end, wk_parsed)

  if not do_binding then
    legendary_tbls = vim.tbl_map(function(item: LegendaryKeymap): LegendaryKeymap
      item[2] = nil
      return item
    end, legendary_tbls)
  end

  return legendary_tbls
end

--- Bind a which-key.nvim table with legendary.nvim
---@param wk_tbls table
---@param wk_opts table
---@param do_binding boolean whether to bind the keymaps or let which-key handle it
function M.bind_whichkey(wk_tbls: {table}, wk_opts: table, do_binding: boolean)
  local legendary_tbls = M.parse_whichkey(wk_tbls, wk_opts, do_binding)
  require('legendary.bindings').bind_keymaps(legendary_tbls)
end

--- Enable auto-registering of which-key.nvim tables
--- with legendary.nvim
function M.whichkey_listen(): boolean
  local loaded, which_key = pcall(
    _G['require'] as (function(module: string): table),
    'which-key'
  )

  if loaded then
    local wk = which_key as table
    local original = wk.register as function(tbls: {table}, opts: table)
    local listener = function(whichkey_tbls: {table}, whichkey_opts: table)
      M.bind_whichkey(whichkey_tbls, whichkey_opts, false)
      original(whichkey_tbls, whichkey_opts)
    end
    wk.register = listener
    return true
  else
    vim.notify('which-key.nvim not available. If you are lazy-loading, be sure that which-key.nvim is added to runtime path before running legendary.nvim config.')
  end
end

return M
