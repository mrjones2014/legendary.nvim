local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local coroutine = _tl_compat and _tl_compat.coroutine or coroutine; local debug = _tl_compat and _tl_compat.debug or debug; local math = _tl_compat and _tl_compat.math or math; local pcall = _tl_compat and _tl_compat.pcall or pcall; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table; require('legendary.types')
local M = {}

local last_scratchpad_buf_id = nil
local last_results_buf_id = nil

local display_strategies = {
   'float',
   'print',
}

function M.create_scratchpad_buffer()
   if last_scratchpad_buf_id ~= nil then
      pcall(vim.api.nvim_buf_delete, last_scratchpad_buf_id, { force = true })
   end

   local buf_id = vim.api.nvim_create_buf(true, true)
   vim.api.nvim_buf_set_option(buf_id, 'filetype', 'lua')
   vim.api.nvim_buf_set_option(buf_id, 'buftype', 'nofile')
   vim.api.nvim_buf_set_name(buf_id, 'Legendary Scratchpad')
   vim.api.nvim_win_set_buf(0, buf_id)
   last_scratchpad_buf_id = buf_id
end

local function create_results_floating_win(lines)
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

   vim.keymap.set('n', 'i', '<NOP>', { buffer = buf_id })

   vim.keymap.set('n', 'q', ':q<CR>', { buffer = buf_id })
   vim.keymap.set('n', '<ESC>', ':q<CR>', { buffer = buf_id })

   vim.api.nvim_buf_set_lines(buf_id, 0, #lines, false, lines)

   vim.api.nvim_buf_set_option(buf_id, 'readonly', true)
   vim.api.nvim_buf_set_option(buf_id, 'modifiable', false)
   last_results_buf_id = buf_id
end

local function print_multiline(str, out_type)
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
   else
      vim.tbl_map(function(line)
         if out_type == 'error' or out_type == 'err' then
            vim.api.nvim_err_writeln(line)
         else
            vim.api.nvim_out_write(string.format('%s\n', line))
         end
      end, lines)
   end
end

local function lua_reader(code_str)
   local ls = (_G)['loadstring']
   local chunk, err = ls(string.format('return \n%s', code_str), '@[legendary-lua-eval]')
   if chunk == nil then
      chunk, err = ls(code_str, '@[legendary-lua-eval]')
   end

   return chunk, err
end

local function lua_pcall(chunk, ...)
   local routine = coroutine.create(chunk)
   local result = { coroutine.resume(routine, ...) }
   if not result[1] then
      (_G)['_errstack'] = routine
      if debug.getinfo(routine, 0, 'f').func ~= chunk then
         result[2] = debug.traceback(routine, result[2], 0)
      end
   end
   return result[1], result[2]
end

function M.exec_lua(lua_str)
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

function M.lua_eval_current_line()
   local current_line = vim.api.nvim_get_current_line()
   M.exec_lua(current_line)
end

function M.lua_eval_line_range(line1, line2)
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
