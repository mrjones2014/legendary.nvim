local M = {}

function M.select(items, opts, callback)
  return vim.ui.select(items, opts, callback)
end

return M
