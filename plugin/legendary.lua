if vim.g.legendary_loaded then
  return
end

if not vim.keymap or not vim.keymap.set then
  vim.notify('Sorry, legendary.nvim requires Neovim 0.7.0 or higher!', vim.log.levels.ERROR)
  return
end

require('legendary-v2.api.cmds').bind()

vim.g.legendary_loaded = true
