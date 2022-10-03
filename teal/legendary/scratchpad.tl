require('legendary.types')
local M = {}

local last_scratchpad_buf_id: integer = nil
local last_results_buf_id: integer = nil

local display_strategies = {
  'float',
  'print',
}

local function create_results_floating_win(lines: {string})
  if last_results_buf_id ~= nil then
    pcall(vim.api.nvim_buf_delete, last_results_buf_id, { force = true })
  end

  local buf_id = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf_id, 'filetype', 'lua')
  vim.api.nvim_buf_set_option(buf_id, 'buftype', 'nofile')
  vim.api.nvim_buf_set_name(buf_id, 'Legendary Scratchpad Results')
  local width = math.floor((vim.o.columns * (2 / 3)) + 0.5)
  local height = math.floor((vim.o.lines * (2 / 3)) + 0.5)
  vim.api.nvim_open_win(buf_id, true, {
    relative = 'editor',
    width = width,
    height = height,
    row = math.floor(((vim.o.lines / 2) - (height / 2)) + 0.5),
    col = math.floor(((vim.o.columns / 2) - (width / 2)) + 0.5),
    anchor = 'NW',
    style = 'minimal',
    border = 'rounded',
  })
  -- prevent going to insert mode in the results buffer
  vim.keymap.set('n', 'i', '<NOP>', { buffer = buf_id as boolean })
  -- map q and esc to :q in the results buffer
  vim.keymap.set('n', 'q', ':q<CR>', { buffer = buf_id as boolean })
  vim.keymap.set('n', '<ESC>', ':q<CR>', { buffer = buf_id as boolean })
  --set the text
  vim.api.nvim_buf_set_lines(buf_id, 0, #lines, false, lines)
  -- make buffer readonly
  vim.api.nvim_buf_set_option(buf_id, 'readonly', true)
  vim.api.nvim_buf_set_option(buf_id, 'modifiable', false)
  last_results_buf_id = buf_id
end

local function print_multiline(str: string, out_type: string)
  local config = require('legendary.config').scratchpad
  local display_strategy = config and config.display_results or 'float'
  if not vim.tbl_contains(display_strategies, display_strategy) then
    display_strategy = 'float'
  end

  if type(str) ~= 'string' then
    str = vim.inspect(str)
  end
  local lines = vim.split(str, '\n', true)

  if display_strategy == 'float' then
    create_results_floating_win(lines)
  else -- print
    vim.tbl_map(function(line: string): nil
      if out_type == 'error' or out_type == 'err' then
        vim.api.nvim_err_writeln(line)
      else
        vim.api.nvim_out_write(string.format('%s\n', line))
      end
    end, lines)
  end
end

local function lua_reader(code_str: string): any, string
  local ls = (_G as table)['loadstring'] as function(str: string, ns: string): any, string
  local chunk, err = ls(string.format('return \n%s', code_str), '@[legendary-lua-eval]')
  if chunk == nil then
    chunk, err = ls(code_str, '@[legendary-lua-eval]')
  end

  return chunk, err
end

local function lua_pcall(chunk: any, ...): boolean, string
  local routine = coroutine.create(chunk as function(...: any): any)
  local result = { coroutine.resume(routine, ...) }
  if not result[1] then
    (_G as table)['_errstack'] = routine
    if debug.getinfo(routine, 0, 'f').func ~= chunk then
      result[2] = debug.traceback(routine, result[2] as string, 0)
    end
  end
  return result[1], result[2] as string
end

function M.exec_lua(lua_str: string)
  local chunk, err = lua_reader(lua_str)
  if chunk == nil then
    print_multiline(err, 'err')
    return
  end

  local st, result = lua_pcall(chunk)
  if st == false then
    print_multiline(result, 'err')
  elseif result ~= nil then
    print_multiline(result)
  end
end

local function load_cache(buf: integer)
  local config = require('legendary.config').scratchpad
  local cache_path = config and config.cache_file or string.format('%s/%s', vim.fn.stdpath('cache'), 'legendary/scratch.lua')
  if vim.fn.filereadable(cache_path) == 0 then
    return
  end

  local lines = {}
  for line in io.lines(cache_path) do
    lines[#lines + 1] = line
  end

  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo.ft = 'lua' -- this needs to be reset on load
end

local function write_cache_autocmd(buf: integer)
  vim.api.nvim_create_autocmd('TextChanged', {
    callback = function()
      pcall(function()
        local config = require('legendary.config').scratchpad
        local cache_path = config and config.cache_file or string.format('%s/%s', vim.fn.stdpath('cache'), 'legendary/scratch.lua')
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local file = io.open(cache_path, 'w+')
        if not file then
          return
        end

        local line_ending = vim.fn.has('win32') == 1 and '\r\n' or '\n'
        file:write(table.concat(lines, line_ending))
        file:close()
      end)
    end,
    buffer = buf,
  })

  vim.api.nvim_create_autocmd('BufReadCmd', {
    callback = function()
      pcall(load_cache, buf)
    end,
    buffer = buf,
  })
end

function M.create_scratchpad_buffer()
  if last_scratchpad_buf_id ~= nil then
    pcall(vim.api.nvim_buf_delete, last_scratchpad_buf_id, { force = true })
  end

  local buf_id = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_buf_set_option(buf_id, 'filetype', 'lua')
  vim.api.nvim_buf_set_option(buf_id, 'buftype', 'nofile')
  vim.api.nvim_buf_set_name(buf_id, 'Legendary Scratchpad')
  pcall(load_cache, buf_id)
  write_cache_autocmd(buf_id)
  vim.api.nvim_win_set_buf(0, buf_id)
  vim.cmd('redrawstatus')
  last_scratchpad_buf_id = buf_id
end



function M.lua_eval_current_line()
  local current_line = vim.api.nvim_get_current_line()
  M.exec_lua(current_line)
end

function M.lua_eval_line_range(line1: integer, line2: integer)
  line1 = line1 - 1
  if line1 < 1 then
    line1 = 1
  end
  local selected_text = vim.api.nvim_buf_get_lines(0, line1 - 1, line2, false)
  M.exec_lua(table.concat(selected_text, '\n'))
end

function M.lua_eval_buf()
  local num_lines = vim.api.nvim_buf_line_count(0)
  local all_lines = vim.api.nvim_buf_get_lines(0, 0, num_lines, false)
  M.exec_lua(table.concat(all_lines, '\n'))
end

return M
