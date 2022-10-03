local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local string = _tl_compat and _tl_compat.string or string; require('legendary.types')
local M = {
   include_builtin = true,
   include_legendary_cmds = true,
   select_prompt = function(kind)
      if kind == 'legendary.items' then
         return 'Legendary'
      end


      return string.gsub(' ' .. kind:gsub('%.', ' '), '%W%l', string.upper):sub(2)
   end,
   formatter = nil,
   most_recent_item_at_top = true,
   keymaps = {},
   commands = {},
   autocmds = {},
   functions = {},
   which_key = {
      mappings = {},
      opts = {},
      do_binding = true,
   },
   auto_register_which_key = true,
   scratchpad = {
      display_results = 'float',
      cache_file = string.format('%s/%s', vim.fn.stdpath('cache'), 'legendary_scratch.lua'),
   },
}

local function default_bool(value, default)
   if value == nil then
      return default
   end
   return value
end

local function default_whichkey(new_config)
   if not new_config then
      return M.which_key
   end

   return {
      mappings = new_config.mappings or {},
      opts = new_config.opts or {},
      do_binding = default_bool(new_config.do_binding, true),
   }
end



function M.setup(new_config)
   new_config = new_config or {}
   if type(new_config) ~= 'table' then
      require('legendary.utils').notify(
      string.format("require('legendary').setup() expects a table, got: %s", type(new_config)))

      return
   end

   M.include_builtin = default_bool(new_config.include_builtin, M.include_builtin)
   M.include_legendary_cmds = default_bool(new_config.include_legendary_cmds, M.include_legendary_cmds)
   M.select_prompt = (new_config.select_prompt or M.select_prompt)
   M.formatter = (new_config.formatter or M.formatter)
   M.most_recent_item_at_top = default_bool(new_config.most_recent_item_at_top, M.most_recent_item_at_top)
   M.keymaps = (new_config.keymaps or M.keymaps)
   M.commands = (new_config.commands or M.commands)
   M.autocmds = (new_config.autocmds or M.autocmds)
   M.functions = (new_config.functions or M.functions)
   M.which_key = default_whichkey(new_config.which_key)
   M.auto_register_which_key = default_bool(new_config.auto_register_which_key, M.auto_register_which_key)
   M.scratchpad = vim.tbl_deep_extend('force', M.scratchpad, (new_config.scratchpad or {}))
   require('legendary.types').validate_config(M)
   return M
end

return M
