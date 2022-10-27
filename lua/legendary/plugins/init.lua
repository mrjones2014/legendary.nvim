local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local pairs = _tl_compat and _tl_compat.pairs or pairs; local pcall = _tl_compat and _tl_compat.pcall or pcall; local string = _tl_compat and _tl_compat.string or string; require('legendary.types')

local M = {}




local function with_defaults(data)
   return vim.tbl_deep_extend("keep", data or {}, {
      keymaps = {},
      commands = {},
      functions = {},
   })
end

local function try_run_plugin(plugin, kind)
   local ok, values = pcall(plugin, kind)
   if not ok then
      return with_defaults()
   end

   return with_defaults(values)
end

local function set_kinds(data)
   for _, keymap in ipairs(data.keymaps) do
      keymap.kind = 'legendary.keymap'
   end

   for _, command in ipairs(data.commands) do
      command.kind = 'legendary.command'
   end

   for _, func in ipairs(data.functions) do
      func.kind = 'legendary.function'
   end

   return data
end

function M.run_plugins(kind)
   local data = with_defaults()

   local plugins = require('legendary.config').plugins
   for plugin_name, enabled in pairs(plugins) do
      if not enabled then
         goto plugins_continue
      end


      local dynrequire = require
      local ok, plugin = pcall(dynrequire, string.format('legendary.plugins.%s', plugin_name))
      if not ok then
         goto plugins_continue
      end

      local values = try_run_plugin(plugin, kind)
      data.keymaps = vim.list_extend(data.keymaps, values.keymaps)
      data.commands = vim.list_extend(data.commands, values.commands)
      data.functions = vim.list_extend(data.functions, values.functions)

      ::plugins_continue::
   end

   return set_kinds(data)
end

return M
