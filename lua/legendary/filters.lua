local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local string = _tl_compat and _tl_compat.string or string

require('legendary.types')

local M = {}





function M.mode(mode)
   return function(item)

      if not string.find(item.kind, 'keymap') then
         return true
      end

      local keymap = item
      local keymap_mode = keymap.mode or { 'n' }
      if type(keymap_mode) == 'string' then
         keymap_mode = { keymap_mode }
      end

      return vim.tbl_contains(keymap_mode, mode)
   end
end




function M.current_mode()
   return M.mode((vim.fn.mode() or 'n'))
end

return M
