if vim.g.legendary_loaded then
  return
end

vim.g.legendary_root_dir = vim.fn.expand('<sfile>:p:h:h')

if not vim.keymap or not vim.keymap.set then
  vim.notify('Sorry, legendary.nvim requires Neovim 0.7.0 or higher!', vim.log.levels.ERROR)
  return
end

require('legendary.api.cmds').bind()

vim.g.legendary_loaded = true
