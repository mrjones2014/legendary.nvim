local M = {
  include_builtin = true,
  keymaps = {},
}

function M.setup(new_config)
  new_config = new_config or {}
  if type(new_config) ~= 'table' then
    vim.api.nvim_err_write(string.format("require('legendary').setup() expects a table, got: %s", type(new_config)))
    return
  end

  M.include_builtin = new_config.include_builtin or M.include_builtin
  M.keymaps = new_config.keymaps or M.keymaps
  if type(M.keymaps) ~= 'table' then
    vim.api.nvim_err_write(string.format('keymaps must be a table, got: %s', type(M.keymaps)))
    return
  end
  if M.keymaps and #M.keymaps > 0 then
    require('legendary').bind(M.keymaps)
  end
end

return M
