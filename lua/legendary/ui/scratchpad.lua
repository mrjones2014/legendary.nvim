local Config = require('legendary.config')
local LuaTools = require('legendary.api.luatools')
local Cache = require('legendary.api.cache')
local Log = require('legendary.log')

local M = {}

local cache = Cache:new('legendary_scratchpad.lua')

local scratchpad_buf_id = nil
local results_buf_id = nil

local function load_from_cache(buf)
  local ok, lines = pcall(function()
    return cache:read()
  end)

  if ok then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_buf_set_option(buf, 'filetype', 'lua') -- this needs to be reset on load
  end
end

local function write_cache(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  pcall(function()
    cache:write(lines)
  end)
end

local function write_cache_autocmd(buf)
  vim.api.nvim_create_autocmd('TextChanged', {
    callback = function()
      write_cache(buf)
    end,
    buffer = buf,
  })

  vim.api.nvim_create_autocmd('BufReadCmd', {
    callback = function()
      load_from_cache(buf)
    end,
    buffer = buf,
  })

  vim.api.nvim_create_autocmd('BufWriteCmd', {
    callback = function()
      write_cache(buf)
    end,
    buffer = buf,
  })
end

---@param size table
---@overload fun(buf:integer,size:table)
local function float(buf, size, minimal)
  local width, height = size.width, size.height
  local win_opts = {
    relative = 'editor',
    width = width,
    height = height,
    col = math.floor((vim.o.columns / 2) - (width / 2)),
    row = math.floor((vim.o.lines / 2) - (height / 2)),
    anchor = 'NW',
    border = Config.scratchpad.float_border,
    zindex = 1,
  }

  if minimal then
    win_opts.style = 'minimal'
  end

  vim.api.nvim_open_win(buf, true, win_opts)
end

local function results_win(result, err)
  local lines = nil
  if err then
    lines = err
  elseif result then
    lines = result
  end

  if not lines then
    Log.warn('[legendary.nvim] No return value from Lua evaluation.')
    return
  end

  if type(lines) ~= 'string' then
    lines = vim.inspect(lines)
  end

  if Config.scratchpad.results_view == 'print' then
    print(lines)
    return
  end

  lines = vim.split(lines, '\n', { trimempty = false })

  if results_buf_id then
    pcall(vim.api.nvim_buf_delete, results_buf_id, { force = true })
  end

  results_buf_id = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(results_buf_id, 'filetype', 'lua')
  vim.api.nvim_buf_set_option(results_buf_id, 'buftype', 'nofile')
  vim.api.nvim_buf_set_name(results_buf_id, 'Legendary Scratchpad Results')
  vim.api.nvim_buf_set_lines(results_buf_id, 0, -1, false, lines)
  -- make buffer readonly
  vim.api.nvim_buf_set_option(results_buf_id, 'readonly', true)
  vim.api.nvim_buf_set_option(results_buf_id, 'modifiable', false)
  vim.api.nvim_buf_set_option(results_buf_id, 'modified', false)

  local width = math.floor((vim.o.columns * (2 / 3)) + 0.5)
  local height = math.floor((vim.o.lines * (2 / 3)) + 0.5)

  vim.api.nvim_create_autocmd('BufLeave', {
    callback = function()
      pcall(vim.api.nvim_buf_delete, results_buf_id, { force = true })
    end,
    buffer = results_buf_id,
  })

  -- prevent going to insert mode in the results buffer
  vim.keymap.set('n', 'i', '<NOP>', { buffer = results_buf_id })
  -- map q and esc to :q in the results buffer
  vim.keymap.set('n', 'q', ':q<CR>', { buffer = results_buf_id })
  vim.keymap.set('n', '<ESC>', ':q<CR>', { buffer = results_buf_id })

  float(results_buf_id, { width = width, height = height }, true)
end

---Open the scratchpad buffer
---@param method 'current'|'split'|'vsplit'|'float'|nil
function M.open(method)
  method = method or Config.scratchpad.view
  if scratchpad_buf_id ~= nil then
    pcall(vim.api.nvim_buf_delete, scratchpad_buf_id, { force = true })
  end

  scratchpad_buf_id = vim.api.nvim_create_buf(method ~= 'float', true)
  vim.api.nvim_buf_set_option(scratchpad_buf_id, 'filetype', 'lua')
  vim.api.nvim_buf_set_option(scratchpad_buf_id, 'buftype', 'acwrite')
  vim.api.nvim_buf_set_name(scratchpad_buf_id, 'Legendary Scratchpad')

  -- we either don't save it, or we're saving it
  -- automatically, so just always set nomodified
  vim.api.nvim_create_autocmd('TextChanged', {
    callback = function()
      ---@diagnostic disable
      vim.defer_fn(function()
        pcall(vim.api.nvim_buf_set_option, scratchpad_buf_id, 'modified', false)
      end, 1)
      ---@diagnostic enable
    end,
    buffer = scratchpad_buf_id,
  })

  if Config.scratchpad.keep_contents then
    load_from_cache(scratchpad_buf_id)
    write_cache_autocmd(scratchpad_buf_id)
  end

  if method == 'current' then
    vim.api.nvim_win_set_buf(0, scratchpad_buf_id)
  elseif method == 'split' or method == 'vsplit' then
    vim.cmd(method)
    vim.api.nvim_win_set_buf(0, scratchpad_buf_id)
  else
    float(scratchpad_buf_id, { width = math.floor(vim.o.columns * 0.85), height = math.floor(vim.o.lines * 0.85) })
  end

  vim.schedule_wrap(function()
    -- if using lspconfig, start lua_lsp
    if vim.fn.exists(':LspStart') ~= 0 then
      vim.cmd(':LspStart lua_ls')
    end
  end)
end

---Close the scratchpad buffer
---@param method 'current'|'split'|'vsplit'|'float'|nil
function M.close(method)
  method = method or Config.scratchpad.view
  if method == 'float' then
    pcall(vim.api.nvim_win_close, vim.api.nvim_get_current_win(), true)
  else
    if method == 'split' or method == 'vsplit' then
      local buf_win = vim.tbl_filter(function(win)
        return vim.api.nvim_win_get_buf(win) == scratchpad_buf_id
      end, vim.api.nvim_list_wins())[1]
      if buf_win then
        pcall(vim.api.nvim_win_close, buf_win, false)
      end
    end
    pcall(vim.api.nvim_buf_delete, scratchpad_buf_id, true)
  end
end

---Toggle the scratchpad buffer
---@param method 'current'|'split'|'vsplit'|'float'|nil
function M.toggle(method)
  if vim.api.nvim_get_current_buf() == scratchpad_buf_id then
    M.close(method)
  else
    M.open(method)
  end
end

function M.lua_eval_buf()
  local all_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local err, result = LuaTools.exec_lua(table.concat(all_lines, '\n'))
  results_win(result, err)
end

function M.lua_eval_range(line1, line2)
  local range = vim.api.nvim_buf_get_lines(0, math.max(line1 - 1, 0), line2, false)
  local err, result = LuaTools.exec_lua(table.concat(range, '\n'))
  results_win(result, err)
end

function M.lua_eval_current_line()
  local current_line = vim.api.nvim_get_current_line()
  local err, result = LuaTools.exec_lua(current_line)
  results_win(result, err)
end

return M
