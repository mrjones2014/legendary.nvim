require('legendary.types')

local COMMANDS = {
  { ':OnedarkproCache', description = 'Update cached highlights for onedarkpro.nvim' },
  { ':OnedarkproClean', description = 'Clean onedarkpro.nvim caches' },
  { ':OnedarkproColors', description = 'Show your configured color palette for onedarkpro.nvim' },
}

return function(kind: LegendaryKind|nil): LegendaryPluginData
  if not kind or #tostring(kind) == 0 or (not not string.find(kind, 'command')) then
    return {
      commands = COMMANDS,
    }
  end

  return {}
end
