if not vim.keymap or not vim.keymap.set then
  vim.api.nvim_err_write('Sorry, legendary.nvim requires Neovim 0.7.0 or higher!')
  return
end

local function find()
  require('legendary').find()
end

vim.api.nvim_add_user_command('Legendary', find, {
  desc = 'Find keymaps and commands with vim.ui.select()',
})

vim.api.nvim_add_user_command('Legend', find, {
  desc = 'Find keymaps and commands with vim.ui.select()',
})
