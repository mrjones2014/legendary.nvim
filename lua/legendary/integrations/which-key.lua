---@mod legendary.integrations.which-key

local State = require('legendary.data.state')
local Keymap = require('legendary.data.keymap')
local Log = require('legendary.log')

local M = {}

---@param wk table
---@param wk_opts table
---@return table
local function wk_to_legendary(wk, wk_opts)
  local legendary = {}
  legendary[1] = wk.prefix
  if wk.cmd then
    legendary[2] = wk.cmd
  end
  if wk_opts and wk_opts.mode then
    legendary.mode = wk_opts.mode
  end
  legendary.description = wk.label or vim.tbl_get(wk, 'opts', 'desc')
  legendary.opts = wk.opts or {}
  return legendary
end

--- Take which-key.nvim tables
--- and parse them into legendary.nvim tables
---@param which_key_tbls table[]
---@param which_key_opts table
---@param do_binding boolean whether to bind the keymaps or let which-key handle it
---@return LegendaryItem[]
function M.parse_whichkey(which_key_tbls, which_key_opts, do_binding)
  if do_binding == nil then
    do_binding = true
  end
  local wk_parsed = require('which-key.mappings').parse(which_key_tbls, which_key_opts)
  local legendary_tbls = {}
  vim.tbl_map(function(wk)
    -- check wk.group because these don't represent standalone keymaps
    -- they basically represent a "folder" of other keymaps
    -- TODO support which-key mappings with buf values
    if vim.tbl_get(wk, 'opts', 'desc') and not wk.group == true then
      table.insert(legendary_tbls, wk_to_legendary(wk, which_key_opts))
    end
  end, wk_parsed)

  if not do_binding then
    legendary_tbls = vim.tbl_map(function(item)
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
function M.bind_whichkey(wk_tbls, wk_opts, do_binding)
  local legendary_tbls = M.parse_whichkey(wk_tbls, wk_opts, do_binding)
  State.items:add(vim.tbl_map(function(keymap)
    local parsed = Keymap:parse(keymap)
    if do_binding then
      parsed:apply()
    end
    return parsed
  end, legendary_tbls))
end

--- Enable auto-registering of which-key.nvim tables
--- with legendary.nvim
function M.whichkey_listen()
  local loaded, which_key = pcall(require, 'which-key')

  if loaded then
    local wk = which_key
    local original = wk.register
    local listener = function(whichkey_tbls, whichkey_opts)
      M.bind_whichkey(whichkey_tbls, whichkey_opts, false)
      original(whichkey_tbls, whichkey_opts)
    end
    wk.register = listener
    return true
  else
    Log.warn(
      'which-key.nvim not available. If you are lazy-loading, be sure that which-key.nvim is added to runtime path '
        .. 'before running legendary.nvim config.'
    )
  end
end

return M
