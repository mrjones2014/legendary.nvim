local function find()
  require('legendary').find()
end

vim.api.nvim_add_user_command('Legendary', find, {
  desc = 'Find keymaps and commands with vim.ui.select()',
})

vim.api.nvim_add_user_command('Legend', find, {
  desc = 'Find keymaps and commands with vim.ui.select()',
})
