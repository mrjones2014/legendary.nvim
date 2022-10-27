require('legendary.types')

local record DiffView
  is_cur_tabpage: function(self:{string:any}): boolean
end

local record DiffViewLib
  views: {DiffView}
end

local COMMANDS = {
  { ':DiffviewOpen', description = 'Open diffview.nvim' },
  { ':DiffviewClose', description = 'Close diffview.nvim' },
  { ':DiffviewLog', description = 'Open the log file for diffview.nvim' },
  { ':DiffviewRefresh', description = 'Refresh diffview.nvim' },
  { ':DiffviewFocusFiles', description = 'Focus the file sidebar of diffview.nvim' },
  { ':DiffviewToggleFiles', description = 'Toggle the files sidebar of diffview.nvim' },
  { ':DiffviewFileHistory', description = 'View current file history in diffview.nvim' },
}

return function(kind: LegendaryKind): LegendaryPluginData
  local data: LegendaryPluginData = {}
  if not kind or #tostring(kind) == 0 or (not not string.find(kind, 'command')) then
    data.commands = COMMANDS
  end

  if not kind or #tostring(kind) == 0 or (not not string.find(kind, 'keymap')) then
    -- workaround Teal type system for dynamic require
    local dynrequire = require
    local ok, diffview_lib = pcall(dynrequire, 'diffview.lib') as (boolean, DiffViewLib)
    if not ok then
      goto plugin_return
    end

    local current_view = vim.tbl_filter(function(view: DiffView): boolean
      return view:is_cur_tabpage()
    end, diffview_lib.views)[1]
    if not current_view then
      goto plugin_return
    end

    -- TODO figure out how to get these dynamically, in case the user has changed them
    --      currently only supports default keymaps
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
