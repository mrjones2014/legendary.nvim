local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local pcall = _tl_compat and _tl_compat.pcall or pcall; local string = _tl_compat and _tl_compat.string or string; require('legendary.types')

local DiffView = {}



local DiffViewLib = {}



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

   if not kind or #tostring(kind) == 0 or (not not string.find(kind, 'keymap')) then

      local dynrequire = require
      local ok, diffview_lib = pcall(dynrequire, 'diffview.lib')
      if not ok then
         goto plugin_return
      end

      local current_view = vim.tbl_filter(function(view)
         return view:is_cur_tabpage()
      end, diffview_lib.views)[1]
      if not current_view then
         goto plugin_return
      end



      data.keymaps = {
         { '<leader>co', description = 'Conflict: choose ours' },
         { '<leader>co', description = 'Conflict: choose theirs' },
         { '<leader>cb', description = 'Conflict: choose base' },
         { '<leader>ca', description = 'Conflict: choose all' },
         { 'dx', description = 'Conflict: choose none' },
         { '[x', description = 'Previous conflict' },
         { ']x', description = 'Next conflict' },
         { '<leader>e', description = 'Focus diffview.nvim files sidebar' },
         { '<leader>b', description = 'Toggle diffview.nvim files sidebar' },
         { '<Tab>', description = 'Next diffview.nvim entry' },
         { '<S-Tab>', description = 'Previous diffview.nvim entry' },
      }
   end

   ::plugin_return::
   return data
end
