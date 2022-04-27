---@mod legendary require('legendary')

require('legendary.types')

local M: table = {}

local wk = require('legendary.compat.which-key')

--- Alias to `require('legendary.compat.which-key).bind_whichkey`
M.bind_whichkey = wk.bind_whichkey

--- Alias to `require('legendary.compat.which-key).parse_whichkey`
M.parse_whichkey = wk.parse_whichkey

--- Alias to `require('legendary.compat.which-key).whichkey_listen`
M.whichkey_listen = wk.whichkey_listen


local b = require('legendary.bindings')

--- Alias to `require('legendary.bindings').bind_keymap`
M.bind_keymap = b.bind_keymap

--- Alias to `require('legendary.bindings').bind_keymaps`
M.bind_keymaps = b.bind_keymaps

--- Alias to `require('legendary.bindings').bind_command`
M.bind_command = b.bind_command

--- Alias to `require('legendary.bindings').bind_commands`
M.bind_commands = b.bind_commands

--- Alias to `require('legendary.bindings').bind_autocmds`
M.bind_autocmds = b.bind_autocmds

--- Set configuration. If config.auto_register_which_key == true
--- and which-key.nvim is loaded to the runtimepath, legendary.nvim
--- will start listening and auto-adding keymaps when added to which-key.nvim
---@param new_config LegendaryConfig
M.setup = function(new_config: table)
  local config = require('legendary.config')
  config.setup(new_config)
  if config.include_builtin then
    require('legendary.builtins').register_builtins()
  end

  if config.include_legendary_cmds then
    require('legendary.cmds').register()
  end

  if config.keymaps and type(config.keymaps) ~= 'table' then
    require('legendary.utils').notify(string.format('keymaps must be a list-like table, got: %s', type(config.keymaps)))
    return
  end

  if config.keymaps and #config.keymaps > 0 then
    require('legendary.bindings').bind_keymaps(config.keymaps)
  end

  if config.commands and type(config.commands) ~= 'table' then
    require('legendary.utils').notify(
      string.format('commands must be a list-like table, got: %s', type(config.commands))
    )
    return
  end

  if config.commands and #config.commands > 0 then
    require('legendary.bindings').bind_commands(config.commands)
  end

  if config.autocmds and #config.autocmds > 0 then
    require('legendary.bindings').bind_autocmds(config.autocmds)
  end

  if config.which_key and config.which_key.mappings and #config.which_key.mappings > 0 then
    require('legendary.compat.which-key').bind_whichkey(
      config.which_key.mappings,
      config.which_key.opts,
      config.which_key.do_binding
    )
  end

  if config.auto_register_which_key then
    local whichkey_is_loaded, _ = pcall((_G['require'] as function(module: string): table), 'which-key')
    if whichkey_is_loaded then
      require('legendary.compat.which-key').whichkey_listen()
    end
  end
end

return M
