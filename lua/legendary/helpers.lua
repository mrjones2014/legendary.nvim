local M = {}

--- Depending on Lua version, you either
--- have to use `table.unpack` or just
--- `unpack` as a global. Make that
--- determination easier by wrapping it.
---@return any the unpacked table
function M.unpack(...)
  if table.unpack == nil then
    return unpack(...)
  else
    return table.unpack(...)
  end
end

--- Given a function reference and some arguments
--- return a new function that will call the original
--- function with the given arguments
---@param fn function
---@return function
function M.lazy(fn, ...)
  local args = { ... }
  return function()
    fn(M.unpack(args))
  end
end

--- Given a Lua path to require, the name of a function in the `require`d module,
--- and some arguments, return a new function that will call
--- the function `fn_name` in module `module_name` with the specified args
---@param module_name string
---@param fn_name string
---@return function
function M.lazy_required_fn(module_name, fn_name, ...)
  local args = { ... }
  return function()
    require(module_name)[fn_name](M.unpack(args))
  end
end

--- Given a Lua function, return a new function
--- that will create a horizontal split before
--- calling the specified function.
---@param fn function
---@return function
function M.split_then(fn)
  return function()
    vim.cmd('sp')
    fn()
  end
end

--- Given a Lua function, return a new function
--- that will create a vertical split before
--- calling the specified function.
---@param fn function
---@return function
function M.vsplit_then(fn)
  return function()
    vim.cmd('vsp')
    fn()
  end
end

return M
