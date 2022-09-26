local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table

require('legendary.types')
local M = {}





function M.rpad(str, len)
   return string.format('%s%s', str, string.rep(' ', len - (vim.fn.strdisplaywidth(str))))
end

local function col1_str(item)
   if vim.startswith(item.kind or '', 'legendary.function') or type((item)[1]) == 'function' then
      return '<function>'
   end

   if vim.startswith(item.kind or '', 'legendary.command') then
      return '<cmd>'
   end

   if vim.startswith(item.kind or '', 'legendary.autocmd') then
      local events = (item)[1]
      if type(events) == 'table' then
         events = table.concat(events, ', ')
      end

      return events
   end

   local modes = (item).mode or 'n'
   if type(modes) == 'table' then
      modes = table.concat(modes, ', ')
   end

   if type((item)[2]) == 'table' then
      modes = table.concat(vim.tbl_keys((item)[2]), ', ')
   end

   return modes
end

local function col2_str(item)
   if vim.startswith(item.kind or '', 'legendary.function') or type((item)[1]) == 'function' then
      return ''
   end

   if vim.startswith(item.kind or '', 'legendary.autocmd') then
      local patterns = (item).opts and ((item).opts).pattern or '*'
      if type(patterns) == 'table' then
         patterns = table.concat(patterns, ', ')
      end

      return patterns
   end

   return (item)[1]
end

local function col3_str(item)
   return item.description or ''
end
















function M.get_default_format_values(item)
   return {
      col1_str(item),
      col2_str(item),
      col3_str(item),
   }
end






function M.get_format_values(item, mode, one_shot_formatter)
   if one_shot_formatter ~= nil then
      local fmt = one_shot_formatter
      local values = fmt(item, mode)

      return vim.list_extend({}, values)
   end

   local formatter = require('legendary.config').formatter
   if formatter and type(formatter) == 'function' then
      local values = formatter(item, mode)

      for i, value in ipairs(values) do
         if type(value) ~= 'string' then
            values[i] = tostring(value or '')
         end
      end

      return values
   end

   return M.get_default_format_values(item)
end






function M.compute_padding(items, mode, formatter)
   local padding = {}
   for _, item in ipairs(items) do
      local values = M.get_format_values(item, mode, formatter)
      for i, value in ipairs(values) do
         local len = vim.fn.strdisplaywidth(value)
         if len > (padding[i] or 0) then
            padding[i] = len
         end
      end
   end

   return padding
end




function M.format(item, mode, padding, formatter)
   local values = M.get_format_values(item, mode, formatter)

   local strs = {}
   for i, value in ipairs(values) do
      table.insert(strs, M.rpad(value, padding[i] or 0))
   end

   local format_str = string.format('%%s%s', string.rep(' │ %s', #values - 1))
   return string.format(format_str, unpack(strs))
end

return M
