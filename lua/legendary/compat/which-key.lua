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
function M.parse_whichkey(which_key_tbls, which_key_opts)
  local wk_parsed = require('which-key.keys').parse_mappings({}, which_key_tbls, which_key_opts.prefix or '')
  local legendary_tbls = {}
  for _, wk in pairs(wk_parsed) do
    -- check wk.group because these don't represent standalone keymaps
    -- they basically represent a "folder" of other keymaps
    -- TODO support which-key mappings with buf values
    if not wk.label or wk.group or wk.buf then
      goto continue
    end

    table.insert(legendary_tbls, wk_to_legendary(wk))

    ::continue::
  end
  return legendary_tbls
end

--- Bind a which-key.nvim table with legendary.nvim
function M.bind_whichkey(wk_tbls, wk_opts)
  local legendary_tbls = M.parse_whichkey(wk_tbls, wk_opts)
  require('legendary').bind_keymaps(legendary_tbls)
end

--- Enable auto-registering of which-key.nvim tables
--- with legendary.nvim
function M.whichkey_listen()
  local wk = require('which-key')
  local original = wk.register
  local listener = function(whichkey_tbls, whichkey_opts)
    M.bind_whichkey(whichkey_tbls, whichkey_opts)
    original(whichkey_tbls, whichkey_opts)
  end
  wk.register = listener
  return true
end

return M
