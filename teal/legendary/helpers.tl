require('legendary.types')
local M = {}

--- Given a function reference and some arguments
--- return a new function that will call the original
--- function with the given arguments
---@param fn function
---@return function
function M.lazy(fn: function(...: any), ...: any): function()
  local args = { ... }
  return function()
    fn(unpack(args))
  end
end

--- Given a Lua path to require, the name of a function in the `require`d module,
--- and some arguments, return a new function that will call
--- the function `fn_name` in module `module_name` with the specified args
---@param module_name string
---@param fn_name string
---@return function
function M.lazy_required_fn(module_name: string, fn_name: string, ...: any): function()
  local args = { ... }
  return function()
    ((_G['require'](module_name) as table)[fn_name] as function(...: any))(unpack(args))
  end
end

--- Given a Lua function, return a new function
--- that will create a horizontal split before
--- calling the specified function.
---@param fn function
---@return function
function M.split_then(fn: function()): function()
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
function M.vsplit_then(fn: function()): function()
  return function()
    vim.cmd('vsp')
    fn()
  end
end

return M
