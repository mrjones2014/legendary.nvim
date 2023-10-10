local State = require('legendary.data.state')
local Keymap = require('legendary.data.keymap')
local Config = require('legendary.config')

local Lazy = require('legendary.vendor.lazy')
---@type ItemGroup
local ItemGroup = Lazy.require_on_exported_call('legendary.data.itemgroup')

local M = {}

local function longest_matching_group(wk, wk_groups)
  local matching_group = {}
  for prefix, group_data in pairs(wk_groups) do
    if vim.startswith(wk.prefix, prefix) and #prefix > #(matching_group[1] or '') then
      matching_group = { prefix, group_data }
    end
  end

  return matching_group[2]
end

---@param wk table
---@param wk_opts table
---@return table
local function wk_to_legendary(wk, wk_opts, wk_groups)
  local legendary = {}
  legendary[1] = wk.prefix
  if wk.cmd then
    legendary[2] = wk.cmd
  end
  if wk_opts and wk_opts.mode then
    legendary.mode = wk_opts.mode
  end
  if wk.group == true and #wk.name > 0 and Config.which_key.use_groups then
    legendary.itemgroup = wk.name
  end
  local group = Config.which_key.use_groups and longest_matching_group(wk, wk_groups) or nil
  if group and Config.which_key.use_groups then
    legendary.itemgroup = group
  end
  legendary.description = wk.label or vim.tbl_get(wk, 'opts', 'desc')
  legendary.opts = wk.opts or {}
  return legendary
end

local function parse_to_itemgroups(legendary_tbls)
  local keymaps = {}
  local itemgroups = {}
  for _, keymap in ipairs(legendary_tbls) do
    if keymap.itemgroup then
      itemgroups[keymap.itemgroup] = itemgroups[keymap.itemgroup]
        or {
          itemgroup = keymap.itemgroup[1],
          description = keymap.itemgroup[1] ~= keymap.itemgroup[2] and keymap.itemgroup[2] or nil,
          keymaps = {},
        }

      table.insert(itemgroups[keymap.itemgroup].keymaps, keymap)
    else
      table.insert(keymaps, keymap)
    end
  end

  local groups = vim.tbl_values(itemgroups)
  return vim.list_extend(keymaps, groups, 1, #groups)
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
  local wk_groups = {}
  vim.tbl_map(function(maybe_group)
    if maybe_group.group == true and maybe_group.name then
      -- empty string for a top-level group without a prefix
      wk_groups[maybe_group.prefix or ''] = { maybe_group.name, maybe_group.label }
    end
  end, wk_parsed)
  vim.tbl_map(function(wk)
    if vim.tbl_get(wk, 'opts', 'desc') and wk.group ~= true then
      table.insert(legendary_tbls, wk_to_legendary(wk, which_key_opts, wk_groups))
    end
  end, wk_parsed)

  if not do_binding then
    legendary_tbls = vim.tbl_map(function(item)
      item[2] = nil
      return item
    end, legendary_tbls)
  end

  return parse_to_itemgroups(legendary_tbls)
end

--- Bind a which-key.nvim table with legendary.nvim
---@param wk_tbls table
---@param wk_opts table
---@param do_binding boolean whether to bind the keymaps or let which-key handle it
function M.bind_whichkey(wk_tbls, wk_opts, do_binding)
  local legendary_tbls = M.parse_whichkey(wk_tbls, wk_opts, do_binding)
  State.items:add(vim.tbl_map(function(keymap)
    local parsed
    if keymap.itemgroup and keymap.keymaps then
      parsed = ItemGroup:parse(keymap)
    else
      parsed = Keymap:parse(keymap)
    end

    if do_binding then
      parsed:apply()
    end
    return parsed
  end, legendary_tbls))
end

return M
