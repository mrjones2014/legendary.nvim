---@mod legendary.helpers require('legendary.helpers')

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

local function is_function(a: any): boolean
  if type(a) == 'function' then
    return true
  end

  local mt = getmetatable(a)
  if not mt then
    return false
  end

  return not not mt.__call
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
    local module = (_G['require'](module_name) as table)
    if string.find(fn_name, '%.') then
      local fn: any = module
      for _, key in ipairs(vim.split(fn_name, '%.')) do
        fn = (fn as table)[key]
        if fn == nil then
          vim.notify('[legendary.nvim]: invalid lazy_required_fn usage: no such function path')
          return
        end
      end
      if not is_function(fn) then
        vim.notify('[legendary.nvim]: invalid lazy_required_fn usage: no such function path')
        return
      end
      local final_fn = fn as function
      final_fn(unpack(args))
    else
      local fn = module[fn_name] as function
      fn(unpack(args))
    end
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
