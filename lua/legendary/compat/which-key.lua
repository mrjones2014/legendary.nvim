local M = {}

local function wk_to_legendary(wk)
  local legendary = {}
  legendary[1] = wk.prefix
  if wk.cmd then
    legendary[2] = wk.cmd
  end
  legendary.description = wk.label
  legendary.opts = wk.opts or {}
  return legendary
end

--- Take which-key.nvim tables
--- and parse them into legendary.nvim tables
---@param which_key_tbls table[]
---@param which_key_opts table
---@return LegendaryItem[]
function M.parse_whichkey(which_key_tbls, which_key_opts)
  local wk_parsed = require('which-key.keys').parse_mappings(
    {},
    which_key_tbls,
    which_key_opts and which_key_opts.prefix or ''
  )
  local legendary_tbls = {}
  vim.tbl_map(function(wk)
    -- check wk.group because these don't represent standalone keymaps
    -- they basically represent a "folder" of other keymaps
    -- TODO support which-key mappings with buf values
    if not wk.label or wk.group or wk.buf then
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
---@param do_binding boolean whether or not to actually bind the keymaps, true by default
function M.bind_whichkey(wk_tbls, wk_opts, do_binding)
  if do_binding == nil then
    do_binding = true
  end
  local legendary_tbls = M.parse_whichkey(wk_tbls, wk_opts)
  require('legendary').bind_keymaps(legendary_tbls, nil, do_binding)
end

--- Enable auto-registering of which-key.nvim tables
--- with legendary.nvim
function M.whichkey_listen()
  local wk = require('which-key')
  local original = wk.register
  local listener = function(whichkey_tbls, whichkey_opts)
    M.bind_whichkey(whichkey_tbls, whichkey_opts, false)
    original(whichkey_tbls, whichkey_opts)
  end
  wk.register = listener
  return true
end

return M
