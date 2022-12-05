local Cache = require('legendary.api.cache')

local logfile = Cache:new('legendary.log')

local levels = {
  'trace',
  'debug',
  'info',
  'warn',
  'error',
  'fatal',
}

local level_hls = {
  trace = 'Comment',
  debug = 'Comment',
  info = 'None',
  warn = 'WarningMsg',
  error = 'ErrorMsg',
  fatal = 'ErrorMsg',
}

local prefix = '[legendary.nvim] '
local prefix_hl = 'Comment'

local function log_with_hl(msg, hl)
  vim.cmd(string.format('echohl %s', prefix_hl))
  vim.cmd(string.format('echom "%s"', vim.fn.escape(prefix, '"')))
  vim.cmd(string.format('echohl %s', hl or 'NONE'))
  vim.cmd(string.format('echom "%s"', vim.fn.escape(msg, '"')))
  vim.cmd('echohl NONE')
end

local function should_log(level)
  local index_of_level = 0
  local index_of_config_level = 0
  for idx, level_str in ipairs(levels) do
    if level_str == level then
      index_of_level = idx
    end

    if level_str == require('legendary.config').log_level then
      index_of_config_level = idx
    end
  end

  return index_of_level >= index_of_config_level
end

local function format(...)
  local args = { ... }

  if #args == 0 then
    return nil
  end

  local template = args[1]
  local template_vars = vim.list_slice(args, 2, #args)
  local ok, msg = pcall(string.format, template, unpack(template_vars))
  if not ok then
    msg = string.format('Could not format string: %s', vim.inspect(args))
  end

  return msg
end

---@class LegendaryLogger
---@field trace fun(...)
---@field debug fun(...)
---@field info fun(...)
---@field warn fun(...)
---@field error fun(...)
---@field fatal fun(...)
local M = {}

for _, level in ipairs(levels) do
  M[level] = function(...)
    local msg = format(...)
    if not msg then
      return
    end

    logfile:append(string.format('[%s]%s%s', os.date(), prefix, msg))

    if not should_log(level) then
      return
    end
    log_with_hl(msg, level_hls[level])
  end
end

---Log at debug level, but run arguments through `vim.inspect` first.
---@param ... any
function M.inspect(...)
  local args = { ... }
  if #args == 0 then
    return
  end
  if #args == 1 then
    args = args[1]
  end

  M.debug(vim.inspect(args))
end

function M.open_log_file()
  vim.cmd(string.format('e %s', logfile:filepath()))
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_create_autocmd({ 'BufEnter', 'CursorHold' }, { buffer = buf, command = 'checktime' })
end

return M
