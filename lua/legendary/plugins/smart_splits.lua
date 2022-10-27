local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local string = _tl_compat and _tl_compat.string or string; require('legendary.types')

local COMMANDS = {
   { ':SmartResizeLeft', description = 'Resize current window towards the left' },
   { ':SmartResizeRight', description = 'Resize current window towards the right' },
   { ':SmartResizeUp', description = 'Resize current window upwards' },
   { ':SmartResizeDown', description = 'Resize current window downwards' },
   { ':SmartCursorMoveLeft', description = 'Move cursor to next window towards the left' },
   { ':SmartCursorMoveRight', description = 'Move cursor to next window towards the right' },
   { ':SmartCursorMoveUp', description = 'Move cursor to next window upwards' },
   { ':SmartCursorMoveDown', description = 'Move cursor to next window downwards' },
   { ':SmartResizeMode', description = 'Start smart-splits.nvim resize mode' },
}

return function(kind)
   if not kind or #tostring(kind) == 0 or (not not string.find(kind, 'command')) then
      return {
         commands = COMMANDS,
      }
   end

   return {}
end