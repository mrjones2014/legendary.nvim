local M = {}

M.disabled_due_to_error = false

function M.is_supported()
  if M.disabled_due_to_error then
    return false
  end

  local has_sqlite, _ = pcall(require, 'sqlite')
  if not has_sqlite then
    return false
  end

  return true
end

return M
