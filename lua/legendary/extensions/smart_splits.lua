---@class LegendarySmartSplitsModKeys
---@field mod string Modifier key to use with directions, typically ctrl or alt/option
---@field prefix string|nil prefix to use for key binding

---@class LegendarySmartSplitsMods
---@field resize string|LegendarySmartSplitsModKeys|boolean resize modifier key def, or false to disable binding
---@field move string|LegendarySmartSplitsModKeys|boolean resize modifier key def, or false to disable binding
---@field swap string|LegendarySmartSplitsModKeys|boolean resize modifier key def, or false to disable binding

---@class LegendarySmartSplitsExtensionOpts
---@field directions string[] Directional keys to use, in order of left/down/up/right (defaults to h/j/k/l).
---@field mods LegendarySmartSplitsMods modifiers to use, defaults to ctrl for move, alt for resize.
---@field mode string[] List of modes to map keys in, defaults to just normal mode

local direction_map = {
  'left',
  'down',
  'up',
  'right',
}

local default_opts = {
  directions = { 'h', 'j', 'k', 'l' },
  mods = {
    move = '<C>',
    resize = '<M>',
    swap = false,
  },
}

---@param opts LegendarySmartSplitsExtensionOpts
return function(opts)
  require('legendary.extensions').pre_ui_hook(function()
    local ok, cmds = pcall(require, 'smart-splits.commands')
    if not ok then
      return false
    end

    local legendary_commands = vim.tbl_map(function(cmd)
      return {
        cmd[1],
        description = cmd[3].desc,
      }
    end, cmds)
    require('legendary').commands(legendary_commands)
    -- once we've got the commands registered, stop looking for them
    return true
  end)

  -- set up keymaps, if desired
  if not opts or type(opts) ~= 'table' then
    return
  end

  opts.directions = opts.directions or { 'h', 'j', 'k', 'l' }
  if #opts.directions ~= 4 then
    require('legendary.log').error(
      "Invalid config for Legendary extension 'smart_splits': "
        .. 'opts.directions must contain 4 values in the same order as h/j/k/l. Got: {}',
      vim.inspect(opts.directions)
    )
    return
  end

  opts = vim.tbl_deep_extend('force', default_opts, opts)

  local t = require('legendary.toolbox')
  local keymaps = {}
  for action, mod in pairs(opts.mods) do
    if mod then
      local mod_stripped
      local prefix = ''
      if type(mod) == 'string' then
        mod_stripped = mod:match('<(.*)>') or mod -- strip off surrounding < > if they exist
      else
        prefix = mod.prefix or ''
        mod_stripped = mod.mod:match('<(.*)>') or mod.mod -- strip off surrounding < > if they exist
      end

      if mod_stripped == nil then
        mod_stripped = ''
      end

      for idx, direction in ipairs(opts.directions) do
        local keys = string.format(#mod_stripped > 0 and '%s<%s-%s>' or '%s%s%s', prefix, mod_stripped, direction)
        local dir_str = direction_map[idx]
        local smart_splits_action
        local desc
        if action == 'resize' then
          smart_splits_action = 'resize'
          desc = string.format('Resize current window %s', dir_str)
        elseif action == 'move' then
          smart_splits_action = 'move_cursor'
          desc = string.format('Move cursor to the %s adjacent window', dir_str)
        elseif action == 'swap' then
          smart_splits_action = 'swap_buf'
          desc = string.format("Swap current window buffer with the %s adjacent window's buffer", dir_str)
        end
        local fn_name = string.format('%s_%s', smart_splits_action, dir_str)
        table.insert(keymaps, {
          keys,
          t.lazy_required_fn('smart-splits', fn_name),
          description = string.format('smart-splits: %s', desc),
          mode = opts.mode,
        })
      end
    end
  end
  require('legendary').keymaps(keymaps)
end
