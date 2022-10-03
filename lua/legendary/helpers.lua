local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local string = _tl_compat and _tl_compat.string or string

require('legendary.types')
local M = {}






function M.lazy(fn, ...)
   local args = { ... }
   return function()
      fn(unpack(args))
   end
end

local function is_function(a)
   if type(a) == 'function' then
      return true
   end

   local mt = getmetatable(a)
   if not mt then
      return false
   end

   return not not mt.__call
end







function M.lazy_required_fn(module_name, fn_name, ...)
   local args = { ... }
   return function()
      local module = (_G['require'](module_name))
      if string.find(fn_name, '%.') then
         local fn = module
         for _, key in ipairs(vim.split(fn_name, '%.')) do
            fn = (fn)[key]
            if fn == nil then
               vim.notify('[legendary.nvim]: invalid lazy_required_fn usage: no such function path')
               return
            end
         end
         if not is_function(fn) then
            vim.notify('[legendary.nvim]: invalid lazy_required_fn usage: no such function path')
            return
         end
         local final_fn = fn
         final_fn(unpack(args))
      else
         local fn = module[fn_name]
         fn(unpack(args))
      end
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
