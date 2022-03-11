vim.cmd([[
  set rtp+=.
  set rtp+=vendor/plenary.nvim
  runtime plugin/plenary.vim
]])
require('plenary.busted')
