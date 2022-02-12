local M = {}

function M.setup(new_config)
  local config = require('legendary.config')
  config.setup(new_config)
  if config.include_builtin then
    require('legendary.builtins').register_builtins()
  end

  if config.keymaps and type(config.keymaps) ~= 'table' then
    vim.api.nvim_err_write(string.format('keymaps must be a list-like table, got: %s', type(config.keymaps)))
    return
  end

  if config.keymaps and #config.keymaps > 0 then
    require('legendary').bind_keymaps(config.keymaps)
  end

  if config.commands and type(config.commands) ~= 'table' then
    vim.api.nvim_err_write(string.format('commands must be a list-like table, got: %s', type(config.commands)))
    return
  end

  if config.commands and #config.commands > 0 then
    require('legendary').bind_commands(config.commands)
  end

  if config.auto_register_which_key then
    local whichkey_is_loaded, _ = pcall(require, 'which-key')
    if whichkey_is_loaded then
      require('legendary.compat.which-key').whichkey_listen()
    end
  end
end

M.bind_whichkey = require('legendary.compat.which-key').bind_whichkey
M = vim.tbl_extend('error', M, require('legendary.bindings'))

if not vim.keymap or not vim.keymap.set then
  local function print_err()
    vim.api.nvim_err_write('Sorry, legendary.nvim requires Neovim 0.7.0 or higher!')
  end

  print_err()
  for key, _ in pairs(M) do
    M[key] = print_err
  end
end

return M
