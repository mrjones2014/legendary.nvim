local M = {}

function M.get_desc(item)
  return item.description or item.desc or vim.item_get(item, 'opts', 'desc') or ''
end

return M
