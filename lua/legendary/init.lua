local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local pcall = _tl_compat and _tl_compat.pcall or pcall; local string = _tl_compat and _tl_compat.string or string

require('legendary.types')

local M = {}

local wk = require('legendary.compat.which-key')






M.bind_whichkey = wk.bind_whichkey








M.parse_whichkey = wk.parse_whichkey




M.whichkey_listen = wk.whichkey_listen


local b = require('legendary.bindings')




M.bind_keymap = b.bind_keymap




M.bind_keymaps = b.bind_keymaps




M.bind_command = b.bind_command




M.bind_commands = b.bind_commands




M.bind_autocmds = b.bind_autocmds





M.setup = function(new_config)
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
      string.format('commands must be a list-like table, got: %s', type(config.commands)))

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
      config.which_key.do_binding)

   end

   if config.auto_register_which_key then
      local whichkey_is_loaded, _ = pcall((_G['require']), 'which-key')
      if whichkey_is_loaded then
         require('legendary.compat.which-key').whichkey_listen()
      end
   end
end

return M
