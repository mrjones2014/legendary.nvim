local M = {}

function M.get_desc(item)
  return item.description or item.desc or vim.tbl_get(item, 'opts', 'desc') or ''
end

function M.bool_default(bool, default)
  if bool == nil then
    return default
  end

  return bool
end

return M
