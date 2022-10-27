local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local string = _tl_compat and _tl_compat.string or string; require('legendary.types')

local COMMANDS = {
   { ':OnedarkproCache', description = 'Update cached highlights for onedarkpro.nvim' },
   { ':OnedarkproClean', description = 'Clean onedarkpro.nvim caches' },
   { ':OnedarkproColors', description = 'Show your configured color palette for onedarkpro.nvim' },
}

return function(kind)
   if not kind or #tostring(kind) == 0 or (not not string.find(kind, 'command')) then
      return {
         commands = COMMANDS,
      }
   end

   return {}
end
