vim.cmd([[
  set rtp+=.
  set rtp+=vendor/plenary.nvim
  set rtp+=vendor/luassert
  runtime plugin/plenary.vim
]])
require('plenary.busted')
