local M = {}

function M.create_scratchpad_buffer()
  local buf_id = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_buf_set_option(buf_id, 'filetype', 'lua')
  vim.api.nvim_buf_set_option(buf_id, 'buftype', 'nofile')
  vim.api.nvim_buf_set_name(buf_id, 'Legendary Scratchpad')
  vim.api.nvim_win_set_buf(0, buf_id)
end

local function print_multiline(str, out_type)
  if type(str) ~= 'string' then
    str = vim.inspect(str)
  end
  local lines = vim.split(str, '\n', true)
  for _, line in pairs(lines) do
    if out_type == 'error' or out_type == 'err' then
      vim.api.nvim_err_writeln(line)
    else
      vim.api.nvim_out_write(string.format('%s\n', line))
    end
  end
end

local function lua_reader(code_str)
  local chunk, err = loadstring(string.format('return \n%s', code_str), '@[legendary-lua-eval]')
  if chunk == nil then
    chunk, err = loadstring(code_str, '@[legendary-lua-eval]')
  end

  return chunk, err
end

local function lua_pcall(chunk, ...)
  local routine = coroutine.create(chunk)
  local result = { coroutine.resume(routine, ...) }
  if not result[1] then
    _G._errstack = routine
    if debug.getinfo(routine, 0, 'f').func ~= chunk then
      result[2] = debug.traceback(routine, result[2], 0)
    end
  end
  return require('legendary.helpers').unpack(result)
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
