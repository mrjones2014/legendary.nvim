-- TODO remove deprecated module

---@deprecated

vim.deprecate("require('legendary.helpers')", "require('legendary.toolbox')", '2.0.1', 'legendary.nvim')
return require('legendary.toolbox')
