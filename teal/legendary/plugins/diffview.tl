require('legendary.types')

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

  return data
end
