local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local pairs = _tl_compat and _tl_compat.pairs or pairs; local string = _tl_compat and _tl_compat.string or string; require('legendary.types')
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
   auto_register_which_key = false,
   scratchpad = {
      display_results = 'float',
      cache_file = string.format('%s/%s', vim.fn.stdpath('cache'), 'legendary_scratch.lua'),
   },
}



function M.setup(new_config)
   new_config = new_config or {}
   if type(new_config) ~= 'table' then
      require('legendary.utils').notify(
      string.format("require('legendary').setup() expects a table, got: %s", type(new_config)))

      return
   end

   local result = vim.tbl_deep_extend("force", M, new_config or {})
   for key, value in pairs(result) do
      (M)[key] = value
   end

   return M
end

return M
