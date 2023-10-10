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

---Remove leading `:` or `<cmd>`,
---remote trailing `<CR>` or `\r`,
---and remove any parameter templates
---like `:bufdo {Cmd}` => `bufdo`
---@param cmd_str any
---@return string
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

---Execute the given keys via `vim.api.nvim_feedkeys`,
---`keys` are escaped using `vim.api.nvim_replace_termcodes`
---@param keys string
function M.exec_feedkeys(keys, noremap)
  local mode = 't'
  if noremap then
    mode = mode .. 'n'
  end
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), mode, true)
end

---Run the given function, timing it's duration and logging the performance
---in milliseconds with the given message. The format string may contain a single `%`
---character, which will be replaced with the duration in milliseconds.
---@generic T
---@param fn function the function to measure performance for
---@param message string the format string to log the performance duration with
---@returns T the result of the given function
function M.log_performance(fn, message)
  local now = vim.loop.hrtime()
  local result = fn()
  require('legendary.log').debug(message, (vim.loop.hrtime() - now) / 1000000)
  return result
end

function M.eq_or_list_contains(needle, haystack)
  if type(needle) == type(haystack) then
    return needle == haystack
  end

  if type(haystack) == 'table' then
    for _, value in ipairs(haystack) do
      if value == needle then
        return true
      end
    end
  end

  return false
end

return M
