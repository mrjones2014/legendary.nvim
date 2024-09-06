vim.cmd([[
  set rtp+=.
  set rtp+=vendor/plenary.nvim
  set rtp+=vendor/luassert
  set rtp+=vendor/sqlite
  runtime plugin/plenary.vim
]])
require('plenary.busted')
