local M = {}

---Get resolved item description. Checks item.description, item.desc, item.opts.desc
---@param item table
---@return string
function M.get_desc(item)
  return item.description or item.desc or vim.tbl_get(item, 'opts', 'desc') or ''
end

---Helper to return a default value if a boolean is nil
---@param bool boolean|nil
---@param default boolean
---@return boolean
function M.bool_default(bool, default)
  if bool == nil then
    return default
  end

  return bool
end

---Check if all items in the table match predicate
---@generic T
---@param tbl T[]
---@param predicate fun(item:T):boolean
---@return boolean
function M.tbl_all(tbl, predicate)
  for _, item in ipairs(tbl) do
    if not predicate(item) then
      return false
    end
  end

  return true
end

function M.sanitize_cmd_str(cmd_str)
  local cmd = (cmd_str .. ''):gsub('%{.*%}$', ''):gsub('%[.*%]$', '')
  if vim.startswith(cmd:lower(), '<cmd>') then
    cmd = cmd:sub(6)
  elseif vim.startswith(cmd, ':') then
    cmd = cmd:sub(2)
  end

  if vim.endswith(cmd:lower(), '<cr>') then
    cmd = cmd:sub(1, #cmd - 4)
  elseif vim.endswith(cmd, '\r') then
    cmd = cmd:sub(1, #cmd - 2)
  end

  return vim.trim(cmd)
end

return M
