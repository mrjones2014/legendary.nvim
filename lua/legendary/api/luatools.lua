local M = {}

local function parse_lua_chunk(code_str)
  local chunk, err = loadstring(string.format('return \n%s', code_str), '@[legendary-lua-eval]')
  if chunk == nil then
    chunk, err = loadstring(code_str, '@[legendary-lua-eval]')
  end

  return err, chunk
end

local function try_exec(chunk, ...)
  local routine = coroutine.create(chunk)
  local result = { coroutine.resume(routine, ...) }
  if not result[1] then
    _G._errstack = routine
    if debug.getinfo(routine, 0, 'f').func ~= chunk then
      result[2] = debug.traceback(routine, result[2], 0)
    end
  end
  return result[1], result[2]
end

---Attempt to execute a Lua string, and return
---its error and result as a tuple (string[], string[])
---@param lua_str string
---@return string|nil,string|nil
function M.exec_lua(lua_str)
  local err, chunk = parse_lua_chunk(lua_str)
  if chunk == nil then
    return err, nil
  end

  local ok, result = try_exec(chunk)
  if not ok then
    return result, nil
  end

  return nil, result
end

return M
