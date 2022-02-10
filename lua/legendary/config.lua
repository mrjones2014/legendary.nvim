local M = {
  include_builtin = true,
  select_prompt = 'Legendary',
  keymaps = {},
  commands = {},
}

function M.setup(new_config)
  new_config = new_config or {}
  M.select_prompt = new_config.select_prompt or M.select_prompt
  if type(new_config) ~= 'table' then
    vim.api.nvim_err_write(string.format("require('legendary').setup() expects a table, got: %s", type(new_config)))
    return
  end

  M.include_builtin = new_config.include_builtin or M.include_builtin
  M.keymaps = new_config.keymaps or M.keymaps
  M.commands = new_config.commands or M.commands
end

return M
