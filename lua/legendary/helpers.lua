-- TODO remove deprecated module

---@deprecated

require('legendary.deprecate').write(
  { "require('legendary.helpers')", 'WarningMsg' },
  'has been replaced by',
  { "require('legendary.toolbox')", 'WarningMsg' }
)

return require('legendary.toolbox')
