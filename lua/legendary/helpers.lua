require('legendary.types')
local M = {}






function M.lazy(fn, ...)
   local args = { ... }
   return function()
      fn(unpack(args))
   end
end







function M.lazy_required_fn(module_name, fn_name, ...)
   local args = { ... }
   return function()
      ((_G['require'](module_name))[fn_name])(unpack(args))
   end
end






function M.split_then(fn)
   return function()
      vim.cmd('sp')
      fn()
   end
end






function M.vsplit_then(fn)
   return function()
      vim.cmd('vsp')
      fn()
   end
end

return M
