local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local pcall = _tl_compat and _tl_compat.pcall or pcall; local table = _tl_compat and _tl_compat.table or table

require('legendary.types')
local M = {}

local function wk_to_legendary(wk, wk_opts)
   local legendary = {}
   legendary[1] = wk.prefix
   if wk.cmd then
      legendary[2] = wk.cmd
   end
   if wk_opts and wk_opts.mode then
      legendary.mode = wk_opts.mode
   end
   legendary.description = wk.label or vim.tbl_get(wk, 'opts', 'desc')
   legendary.opts = wk.opts or {}
   return legendary
end







function M.parse_whichkey(which_key_tbls, which_key_opts, do_binding)
   if do_binding == nil then
      do_binding = true
   end
   local wk_parsed = ((_G['require']('which-key.mappings')).parse)(
   which_key_tbls,
   which_key_opts)

   local legendary_tbls = {}
   vim.tbl_map(function(wk)



      if not vim.tbl_get(wk, 'opts', 'desc') or wk.group == true then
         goto continue
      end

      table.insert(legendary_tbls, wk_to_legendary(wk, which_key_opts))

      ::continue::
   end, wk_parsed)

   if not do_binding then
      legendary_tbls = vim.tbl_map(function(item)
         item[2] = nil
         return item
      end, legendary_tbls)
   end

   return legendary_tbls
end





function M.bind_whichkey(wk_tbls, wk_opts, do_binding)
   local legendary_tbls = M.parse_whichkey(wk_tbls, wk_opts, do_binding)
   require('legendary.bindings').bind_keymaps(legendary_tbls)
end



function M.whichkey_listen()
   local loaded, which_key = pcall(
   _G['require'],
   'which-key')


   if loaded then
      local wk = which_key
      local original = wk.register
      local listener = function(whichkey_tbls, whichkey_opts)
         M.bind_whichkey(whichkey_tbls, whichkey_opts, false)
         original(whichkey_tbls, whichkey_opts)
      end
      wk.register = listener
      return true
   else
      vim.notify('which-key.nvim not available. If you are lazy-loading, be sure that which-key.nvim is added to runtime path before running legendary.nvim config.')
   end
end

return M
