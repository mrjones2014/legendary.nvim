local M = {}

local keymaps = require('legendary.config').keymaps
local commands = require('legendary.config').commands

local Formatter = require('legendary.formatter').Formatter

--- Bind a single keymap with legendary.nvim
---@param keymap LegendaryItem
function M.bind_keymap(keymap)
  keymap.kind = 'legendary-keymap'
  if not keymap or type(keymap) ~= 'table' then
    require('legendary.util').notify(string.format('Expected table, got %s', type(keymap)))
    return
  end

  -- always bind the keymaps in case they are buffer-specific
  require('legendary.util').set_keymap(keymap)

  if require('legendary.util').contains_duplicates(keymaps, keymap) then
    return
  end

  require('legendary.formatter').update_padding(keymap)

  if keymap.description and #keymap.description > 0 then
    table.insert(keymaps, Formatter(keymap))
  end
end

--- Bind a list of keymaps with legendary.nvim
---@param new_keymaps LegendaryItem[]
function M.bind_keymaps(new_keymaps)
  if not new_keymaps or type(new_keymaps) ~= 'table' then
    return
  end

  if not new_keymaps or not new_keymaps[1] or type(new_keymaps[1]) ~= 'table' then
    require('legendary.util').notify(
      string.format('Expected list-like table, got %s', type(new_keymaps and new_keymaps[1] or nil))
    )
    return
  end

  for _, keymap in pairs(new_keymaps) do
    M.bind_keymap(keymap)
  end
end

--- Bind a single command with legendary.nvim
---@param cmd LegendaryItem
function M.bind_command(cmd)
  cmd.kind = 'legendary-command'
  if not cmd or type(cmd) ~= 'table' then
    require('legendary.util').notify(string.format('Expected table, got %s', type(cmd)))
    return
  end

  -- always set the command in case it's buffer-specific
  require('legendary.util').set_command(cmd)

  if require('legendary.util').contains_duplicates(commands, cmd) then
    return
  end

  require('legendary.formatter').update_padding(cmd)

  if cmd.description and #cmd.description > 0 then
    table.insert(commands, Formatter(cmd))
  end
end

--- Bind a list of commands with legendary.nvim
---@param cmds LegendaryItem[]
function M.bind_commands(cmds)
  if not cmds or type(cmds) ~= 'table' then
    return
  end

  if not cmds or not cmds[1] or type(cmds[1]) ~= 'table' then
    require('legendary.util').notify(string.format('Expected list-like table, got %s', type(cmds and cmds[1] or nil)))
    return
  end

  for _, cmd in pairs(cmds) do
    M.bind_command(cmd)
  end
end

--- Find keymaps, commands, or both (both by default)
--- with legendary.nvim. To find only keymaps, pass
--- "keymaps" as a parameter, pass "commands" to find
--- only commands.
---@param type string
function M.find(type)
  local current_mode = vim.fn.mode()
  local cursor_position = vim.api.nvim_win_get_cursor(0)
  local current_window_num = vim.api.nvim_win_get_number(0)
  local items
  if type == 'keymaps' then
    items = keymaps
  elseif type == 'commands' then
    items = commands
  else
    items = require('legendary.util').concat_lists(keymaps, commands)
  end
  vim.ui.select(items, {
    prompt = require('legendary.config').select_prompt,
    kind = string.format('legendary-%', type or 'items'),
  }, function(selected)
    -- vim.schedule so that the select UI closes before we do anything
    vim.schedule(function()
      require('legendary.executor').try_execute(selected)

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
