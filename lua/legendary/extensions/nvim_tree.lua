local function init()
  local keymaps = require('nvim-tree.api').config.mappings.get_keymap()
  local legendary_keymaps = vim.tbl_map(function(keymap)
    return {
      keymap.lhs,
      description = keymap.desc,
      mode = keymap.mode,
      filters = { filetype = 'NvimTree' },
    }
  end, keymaps)
  require('legendary').keymaps(legendary_keymaps)
end

return function()
  -- check if nvim-tree has already been loaded
  if vim.g.NvimTreeRequired and vim.g.NvimTreeSetup then
    init()
  else
    vim.api.nvim_create_autocmd('User', {
      pattern = 'NvimTreeSetup',
      callback = init,
      once = true,
    })
  end
end
