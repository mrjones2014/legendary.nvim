local M = {}

local keymaps = require('legendary.config').keymaps
local commands = require('legendary.config').commands
local autocmds = require('legendary.config').autocmds

local Formatter = require('legendary.formatter').Formatter

--- Bind a single keymap with legendary.nvim
---@param keymap LegendaryItem
function M.bind_keymap(keymap, kind)
  if not keymap or type(keymap) ~= 'table' then
    require('legendary.utils').notify(string.format('Expected table, got %s', type(keymap)))
    return
  end

  -- always bind the keymaps in case they are buffer-specific
  require('legendary.utils').set_keymap(keymap)

  if require('legendary.utils').list_contains(keymaps, keymap) then
    return
  end

  if keymap.description and #keymap.description > 0 then
    keymap.kind = kind or 'legendary.keymap'
    require('legendary.formatter').update_padding(keymap)
    table.insert(keymaps, Formatter(keymap))
  end
end

--- Bind a list of keymaps with legendary.nvim
---@param new_keymaps LegendaryItem[]
function M.bind_keymaps(new_keymaps, kind)
  if not new_keymaps or type(new_keymaps) ~= 'table' then
    return
  end

  if not new_keymaps or not new_keymaps[1] or type(new_keymaps[1]) ~= 'table' then
    require('legendary.utils').notify(
      string.format('Expected list-like table, got %s', type(new_keymaps and new_keymaps[1] or nil))
    )
    return
  end

  for _, keymap in pairs(new_keymaps) do
    M.bind_keymap(keymap, kind)
  end
end

--- Bind a single command with legendary.nvim
---@param cmd LegendaryItem
function M.bind_command(cmd, kind)
  if not cmd or type(cmd) ~= 'table' then
    require('legendary.utils').notify(string.format('Expected table, got %s', type(cmd)))
    return
  end

  -- always set the command in case it's buffer-specific
  require('legendary.utils').set_command(cmd)

  if require('legendary.utils').list_contains(commands, cmd) then
    return
  end

  if cmd.description and #cmd.description > 0 then
    cmd.kind = kind or 'legendary.command'
    require('legendary.formatter').update_padding(cmd)
    table.insert(commands, Formatter(cmd))
  end
end

--- Bind a list of commands with legendary.nvim
---@param cmds LegendaryItem[]
function M.bind_commands(cmds, kind)
  if not cmds or type(cmds) ~= 'table' then
    return
  end

  if not cmds or not cmds[1] or type(cmds[1]) ~= 'table' then
    require('legendary.utils').notify(string.format('Expected list-like table, got %s', type(cmds and cmds[1] or nil)))
    return
  end

  for _, cmd in pairs(cmds) do
    M.bind_command(cmd, kind)
  end
end

--- Bind a single autocmd with legendary.nvim
---@param autocmd LegendaryItem
local function bind_autocmd(autocmd, group, kind)
  if not vim.api.nvim_create_augroup then
    require('legendary.utils').notify(
      --luacheck: ignore
      'Sorry, managing autocmds via legendary.nvim is only supported on Neovim 0.7+ (requires `vim.api.nvim_create_augroup` and `vim.api.nvim_create_autocmd` API functions).'
    )
    return
  end

  if not autocmd or type(autocmd) ~= 'table' then
    require('legendary.utils').notify(string.format('Expected table, got %s', type(autocmd)))
    return
  end

  -- always set autocmd in case it is buffer-specific
  require('legendary.utils').set_autocmd(autocmd, group)

  if require('legendary.utils').list_contains(autocmds, autocmd) then
    return
  end

  if autocmd.description and #autocmd.description > 0 then
    autocmd.kind = kind or 'legendary.autocmd'
    require('legendary.formatter').update_padding(autocmd)
    table.insert(autocmds, Formatter(autocmd))
  end
end

--- Bind an augroup of autocmds
---@param augroup LegendaryAugroup
local function bind_augroup(augroup, kind)
  if not vim.api.nvim_create_augroup then
    require('legendary.utils').notify(
      --luacheck: ignore
      'Sorry, managing autocmds via legendary.nvim is only supported on Neovim 0.7+ (requires `vim.api.nvim_create_augroup` and `vim.api.nvim_create_autocmd` API functions).'
    )
    return
  end

  local group_name = augroup and augroup.name or ''
  if #group_name == 0 then
    require('legendary.utils').notify('augroup must have a name')
    return
  end

  local clear = augroup and augroup.clear
  if clear == nil then
    clear = true
  end

  vim.api.nvim_create_augroup(group_name, { clear = clear })

  for key, autocmd in pairs(augroup) do
    if type(key) == 'number' then
      autocmd.opts = autocmd.opts or {}
      autocmd.opts.group = group_name
      bind_autocmd(autocmd, group_name, kind)
    end
  end
end

--- Bind a list of mixed augroups and autocmds
---@param au LegendaryAugroup[] | LegendaryItem[]
function M.bind_autocmds(au, kind)
  if require('legendary.utils').is_user_augroup(au) then
    bind_augroup(au)
  elseif require('legendary.utils').is_user_autocmd(au) then
    bind_autocmd(au)
  else
    for _, augroup_or_autocmd in pairs(au) do
      if require('legendary.utils').is_user_augroup(augroup_or_autocmd) then
        bind_augroup(augroup_or_autocmd, kind)
      elseif require('legendary.utils').is_user_autocmd(augroup_or_autocmd) then
        bind_autocmd(augroup_or_autocmd, kind)
      end
    end
  end
end

--- Find keymaps, commands, or both (both by default)
--- with legendary.nvim. To find only keymaps, pass
--- "keymaps" as a parameter, pass "commands" to find
--- only commands, pass "autocmds" to find only autocmds.
---@param type string
function M.find(type)
  local current_mode = vim.fn.mode()
  local visual_selection = nil
  if current_mode and current_mode:sub(1, 1):lower() == 'v' then
    visual_selection = require('legendary.utils').get_marks()
    require('legendary.utils').send_escape_key()
  end
  local cursor_position = vim.api.nvim_win_get_cursor(0)
  local current_window_num = vim.api.nvim_win_get_number(0)
  local items
  if type == 'keymaps' then
    items = keymaps
  elseif type == 'commands' then
    items = commands
  elseif type == 'autocmds' then
    items = autocmds
  else
    local concat = require('legendary.utils').concat_lists
    items = concat(concat(keymaps, commands), autocmds)
  end

  vim.ui.select(items, {
    prompt = require('legendary.config').select_prompt,
    kind = string.format('legendary.%s', type or 'items'),
  }, function(selected)
    -- vim.schedule so that the select UI closes before we do anything
    vim.schedule(function()
      require('legendary.executor').try_execute(selected, visual_selection)

      -- only restore cursor position if we're going back
      -- to the same window
      if vim.api.nvim_win_get_number(0) ~= current_window_num then
        return
      end

      -- some commands close the buffer, in those cases this will fail
      -- so wrap it in pcall
      pcall(function()
        vim.api.nvim_win_set_cursor(0, cursor_position)
        -- if we were in normal or insert mode, go back to it
        if current_mode == 'n' then
          vim.cmd('stopinsert')
        elseif current_mode == 'i' then
          vim.cmd('startinsert')
        end
      end)
    end)
  end)
end

return M
