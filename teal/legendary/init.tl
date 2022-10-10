---@mod legendary require('legendary')

require('legendary.types')

local M: table = {}

local wk = require('legendary.compat.which-key')

--- Alias to `require('legendary.compat.which-key).bind_whichkey`
--- Bind a which-key.nvim table with legendary.nvim
---@param wk_tbls table
---@param wk_opts table
---@param do_binding boolean whether to bind the keymaps or let which-key handle it
M.bind_whichkey = wk.bind_whichkey

--- Alias to `require('legendary.compat.which-key).parse_whichkey`
--- Take which-key.nvim tables
--- and parse them into legendary.nvim tables
---@param which_key_tbls table[]
---@param which_key_opts table
---@param do_binding boolean whether to bind the keymaps or let which-key handle it
---@return LegendaryItem[]
M.parse_whichkey = wk.parse_whichkey

--- Alias to `require('legendary.compat.which-key).whichkey_listen`
--- Enable auto-registering of which-key.nvim tables
--- with legendary.nvim
M.whichkey_listen = wk.whichkey_listen


local b = require('legendary.bindings')

--- Alias to `require('legendary.bindings').bind_keymap`
--- Bind a single keymap with legendary.nvim
---@param keymap LegendaryItem
M.bind_keymap = b.bind_keymap

--- Alias to `require('legendary.bindings').bind_keymaps`
--- Bind a list of keymaps with legendary.nvim
---@param new_keymaps LegendaryItem[]
M.bind_keymaps = b.bind_keymaps

--- Alias to `require('legendary.bindings').bind_command`
--- Bind a single command with legendary.nvim
---@param cmd LegendaryItem
M.bind_command = b.bind_command

--- Alias to `require('legendary.bindings').bind_commands`
--- Bind a list of commands with legendary.nvim
---@param cmds LegendaryItem[]
M.bind_commands = b.bind_commands

--- Alias to `require('legendary.bindings').bind_autocmds`
--- Bind a list of mixed augroups and autocmds
---@param au LegendaryAugroup[] | LegendaryItem[]
M.bind_autocmds = b.bind_autocmds

--- Alias to `require('legendary.bindings').bind_function`
--- Bind a single function with legendary.nvim
---@param function LegendaryFunction
M.bind_function = b.bind_function

--- Alias to `require('legendary.bindings').bind_functions`
--- Bind a list of functions with legendary.nvim
---@param functions LegendaryFunctions[]
M.bind_functions = b.bind_functions

--- Alias to `require('legendary.bindings).find`
--- Find keymaps, commands, or both (both by default)
--- with legendary.nvim. To find only keymaps, pass
--- "keymaps" as a parameter, pass "commands" to find
--- only commands, pass "autocmds" to find only autocmds,
--- pass 'functions' to find only functions.
---@param item_kind string | nil
---@param filters {LegendaryItemFilter} | nil
M.find = b.find

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

  if config.functions and type(config.functions) ~= 'table' then
    require('legendary.utils').notify(
      string.format('functions must be a list-like table, got: %s', type(config.functions))
    )
    return
  end

  if config.functions and #config.functions > 0 then
    require('legendary.bindings').bind_functions(config.functions)
  end

  if config.which_key and config.which_key.mappings and #config.which_key.mappings > 0 then
    require('legendary.compat.which-key').bind_whichkey(
      config.which_key.mappings,
      config.which_key.opts,
      config.which_key.do_binding
    )
  end

  if config.auto_register_which_key then
    require('legendary.compat.which-key').whichkey_listen()
  end
end

return M
