local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local pcall = _tl_compat and _tl_compat.pcall or pcall; local string = _tl_compat and _tl_compat.string or string; require('legendary.types')
local M = {}

local function mode_from_table(modes, current_mode)
   if vim.tbl_contains(modes, current_mode) then
      return current_mode
   end

   for _, mode in ipairs(modes) do
      if mode == 'n' then
         return mode
      end

      if mode == 'i' then
         return mode
      end
   end

   return nil
end

local function exec(item, mode, visual_selection)
   local utils = require('legendary.utils')
   local cmd = utils.get_definition(item, mode)
   local opts = utils.resolve_opts(item, mode)

   if mode == 'n' then
      vim.cmd('stopinsert')
   elseif mode == 'i' then
      vim.cmd('startinsert')
   elseif mode == 'v' then
      vim.cmd('normal! gv')
   end

   if type(cmd) == 'function' then
      (cmd)(visual_selection)
   else
      if (item).unfinished then
         vim.cmd('stopinsert')


         cmd = (cmd):gsub('{.*}$', ''):gsub('%[.*%]$', '')

         cmd = require('legendary.utils').strip_trailing_cr(cmd)
      elseif opts.expr then
         cmd = (item)[1]
      elseif vim.startswith(item.kind, 'legendary.command') then
         vim.cmd(require('legendary.utils').strip_leading_cmd_char(cmd))
         return
      end

      cmd = vim.api.nvim_replace_termcodes(cmd, true, false, true)
      vim.api.nvim_feedkeys(cmd, 't', true)
   end
end



function M.try_execute(item, current_buf, visual_selection, current_mode, current_cursor_pos)
   if not item then
      return
   end

   local mode = (item).mode or 'n'

   if visual_selection then
      mode = 'v'
   elseif type(mode) == 'table' then
      mode = mode_from_table(mode)
   end

   if mode == 'x' and visual_selection then
      mode = 'v'
   end

   if mode == nil or (mode ~= 'n' and mode ~= 'i' and not require('legendary.utils').is_visual_mode(mode)) then
      require('legendary.utils').notify(
      'Executing keybinds is only supported for insert, normal, and visual mode bindings.',
      vim.log.levels.INFO)

      return
   end

   exec(item, mode, visual_selection)

   vim.schedule(function()
      if vim.api.nvim_get_current_buf() ~= current_buf then
         return
      end


      pcall(vim.api.nvim_win_set_cursor, 0, current_cursor_pos)
      if current_mode == 'n' then
         vim.cmd('stopinsert')
      elseif current_mode == 'i' then
         vim.cmd('startinsert')
      end
   end)
end

return M
