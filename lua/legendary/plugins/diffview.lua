local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local string = _tl_compat and _tl_compat.string or string; require('legendary.types')

local COMMANDS = {
   { ':DiffviewOpen', description = 'Open diffview.nvim' },
   { ':DiffviewClose', description = 'Close diffview.nvim' },
   { ':DiffviewLog', description = 'Open the log file for diffview.nvim' },
   { ':DiffviewRefresh', description = 'Refresh diffview.nvim' },
   { ':DiffviewFocusFiles', description = 'Focus the file sidebar of diffview.nvim' },
   { ':DiffviewToggleFiles', description = 'Toggle the files sidebar of diffview.nvim' },
   { ':DiffviewFileHistory', description = 'View current file history in diffview.nvim' },
}

return function(kind)
   local data = {}
   if not kind or #tostring(kind) == 0 or (not not string.find(kind, 'command')) then
      data.commands = COMMANDS
   end

   return data
end
