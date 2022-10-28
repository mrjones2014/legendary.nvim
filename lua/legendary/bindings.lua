local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local ipairs = _tl_compat and _tl_compat.ipairs or ipairs; local string = _tl_compat and _tl_compat.string or string; local table = _tl_compat and _tl_compat.table or table; local types = require('legendary.types')
local M = {}

local _current_id = 0
local function next_id()
   _current_id = _current_id + 1
   return _current_id
end

local last_used_item

local keymaps = require('legendary.config').keymaps
local commands = require('legendary.config').commands
local autocmds = require('legendary.config').autocmds
local functions = require('legendary.config').functions

local utils = require('legendary.utils')
local formatter = require('legendary.formatter')
local plugin_manager = require('legendary.plugin-manager')



function M.bind_keymap(keymap, kind)
   keymap = utils.resolve_description(keymap)
   keymap.kind = (kind or 'legendary.keymap')
   keymap.id = next_id()
   types.validate_keymap(keymap)

   if not keymap or type(keymap) ~= 'table' then
      utils.notify(string.format('Expected table, got %s', type(keymap)))
      return
   end

   if utils.list_contains(keymaps, keymap) then
      return
   end

   if keymap.opts and (keymap.opts.buffer == 0 or keymap.opts.buffer == true) then
      keymap.opts.buffer = vim.api.nvim_get_current_buf()
   end

   utils.set_keymap(keymap)
   for _, resolved_keymap in ipairs(utils.resolve_with_per_mode_description(keymap)) do
      keymap.id = next_id()
      table.insert(keymaps, resolved_keymap)
   end
end



function M.bind_keymaps(new_keymaps, kind)
   if not new_keymaps or type(new_keymaps) ~= 'table' then
      return
   end

   if not vim.tbl_islist(new_keymaps) then
      utils.notify(
      string.format('Expected list-like table, got %s, at require("legendary").bind_keymaps', type(new_keymaps)))

      return
   end

   vim.tbl_map(function(keymap)
      M.bind_keymap(keymap, kind)
   end, new_keymaps)
end



function M.bind_command(cmd, kind)
   cmd = utils.resolve_description(cmd)
   cmd.kind = (kind or 'legendary.command')
   cmd.id = next_id()
   types.validate_command(cmd)
   if not cmd or type(cmd) ~= 'table' then
      utils.notify(string.format('Expected table, got %s', type(cmd)))
      return
   end

   if cmd.opts and cmd.opts.buffer == 0 then
      cmd.opts.buffer = vim.api.nvim_get_current_buf()
   end

   if utils.list_contains(commands, cmd) then
      return
   end

   utils.set_command(cmd)
   table.insert(commands, cmd)
end



function M.bind_commands(cmds, kind)
   if not cmds or type(cmds) ~= 'table' then
      return
   end

   if not vim.tbl_islist(cmds) then
      utils.notify(
      string.format('Expected list-like table, got %s, at require("legendary").bind_commands', type(cmds)))

      return
   end

   vim.tbl_map(function(cmd)
      M.bind_command(cmd, kind)
   end, cmds)
end



local function bind_autocmd(autocmd, group, kind)
   autocmd = utils.resolve_description(autocmd)
   autocmd.kind = (kind or 'legendary.autocmd')
   autocmd.id = next_id()
   types.validate_autocmd(autocmd)

   if not vim.api.nvim_create_augroup then
      utils.notify(
      'Sorry, managing autocmds via legendary.nvim is only supported on Neovim 0.7+ (requires `vim.api.nvim_create_augroup` and `vim.api.nvim_create_autocmd` API functions).')

      return
   end

   if not autocmd or type(autocmd) ~= 'table' then
      utils.notify(string.format('Expected table, got %s', type(autocmd)))
      return
   end

   if utils.list_contains(autocmds, autocmd) then
      return
   end

   if autocmd.opts and autocmd.opts.buffer == 0 then
      autocmd.opts.buffer = vim.api.nvim_get_current_buf()
   end

   utils.set_autocmd(autocmd, group)
   if autocmd.description and #autocmd.description > 0 and not (autocmd.opts or {}).once then
      table.insert(autocmds, autocmd)
   end
end



local function bind_augroup(augroup, kind)
   augroup = utils.resolve_description(augroup)
   types.validate_augroup(augroup)
   if not vim.api.nvim_create_augroup then
      utils.notify(

      'Sorry, managing autocmds via legendary.nvim is only supported on Neovim 0.7+ (requires `vim.api.nvim_create_augroup` and `vim.api.nvim_create_autocmd` API functions).')

      return
   end

   local group_name = augroup and augroup.name or ''
   if #group_name == 0 then
      utils.notify('augroup must have a name')
      return
   end

   local clear = augroup and augroup.clear
   if clear == nil then
      clear = true
   end

   vim.api.nvim_create_augroup(group_name, { clear = clear })

   for _, autocmd in ipairs(augroup) do
      autocmd.opts = autocmd.opts or {}
      autocmd.opts.group = group_name
      bind_autocmd(autocmd, group_name, kind)
   end
end



function M.bind_autocmds(au, kind)
   if utils.is_user_augroup(au) then
      bind_augroup(au)
   elseif utils.is_user_autocmd(au) then
      bind_autocmd(au)
   else
      vim.tbl_map(function(augroup_or_autocmd)
         if utils.is_user_augroup(augroup_or_autocmd) then
            bind_augroup(augroup_or_autocmd, kind)
         elseif utils.is_user_autocmd(augroup_or_autocmd) then
            bind_autocmd(augroup_or_autocmd, kind)
         end
      end, au)
   end
end



function M.bind_function(fn, kind)
   fn = utils.resolve_description(fn)
   fn.kind = (kind or 'legendary.function')
   fn.id = next_id()
   types.validate_function(fn)

   if not fn or type(fn) ~= 'table' then
      utils.notify(string.format('Expected table, got %s', type(fn)))
      return
   end

   if fn.opts and fn.opts.buffer == 0 then
      fn.opts.buffer = vim.api.nvim_get_current_buf()
   end

   if utils.list_contains(functions, fn) then
      return
   end

   table.insert(functions, fn)
end



function M.bind_functions(fns, kind)
   if not fns or type(fns) ~= 'table' then
      return
   end

   if not vim.tbl_islist(fns) then
      utils.notify(
      string.format('Expected list-like table, got %s, at require("legendary").bind_functions', type(fns)))

      return
   end

   vim.tbl_map(function(fn)
      M.bind_function(fn, kind)
   end, fns)
end







function M.find(opts, _deprecated)
   opts = opts or {}

   if type(opts) ~= 'table' or _deprecated ~= nil then
      opts = {}
      vim.notify("The API for `require('legendary').find()` has changed, please see https://github.com/mrjones2014/legendary.nvim#usage and update your usages.")
   end

   local item_kind = opts.kind or ''
   local current_mode = (vim.fn.mode() or '')
   local current_buf = vim.api.nvim_get_current_buf()
   local visual_selection = nil
   if utils.is_visual_mode(current_mode) then
      visual_selection = utils.get_marks()
      utils.send_escape_key()
   end
   local cursor_position = vim.api.nvim_win_get_cursor(0)
   local plugins_data = plugin_manager.run_plugins(item_kind)
   local items
   if string.find(item_kind, 'keymap') then
      items = keymaps
      items = vim.list_extend(items, plugins_data.keymaps)
   elseif string.find(item_kind, 'command') then
      items = commands
      items = vim.list_extend(items, plugins_data.commands)
   elseif string.find(item_kind, 'autocmd') then
      items = autocmds
   elseif item_kind == 'legendary.function' then
      items = functions
      items = vim.list_extend(items, plugins_data.functions)
   else
      items = vim.list_extend({}, keymaps)
      items = vim.list_extend(items, commands)
      items = vim.list_extend(items, autocmds)
      items = vim.list_extend(items, functions)
      items = vim.list_extend(items, plugins_data.keymaps)
      items = vim.list_extend(items, plugins_data.commands)
      items = vim.list_extend(items, plugins_data.functions)
   end


   if
require('legendary.config').most_recent_item_at_top and
      last_used_item and
      type(item_kind) == 'string' and
      vim.startswith(last_used_item.kind, item_kind) then

      for i, item in ipairs(items) do
         if item.id == last_used_item.id then

            table.remove(items, i)
            table.insert(items, 1, item)
            goto last_used_item_found
         end
      end

      ::last_used_item_found::
   end

   local filters = opts.filters or {}
   if type(filters) == 'function' then
      filters = { filters }
   end


   table.insert(filters, function(item)
      return item.opts == nil or item.opts.buffer == nil or item.opts.buffer == current_buf
   end)

   for _, filter in ipairs(filters) do
      if type(filter) ~= 'function' then
         utils.notify('Passed an item filter that is not a function', vim.log.levels.WARN)
         goto skip_filter
      end

      items = vim.tbl_filter(function(item)
         local result = filter(item)
         if type(result) ~= 'boolean' then
            return true
         end

         return result
      end, items)

      ::skip_filter::
   end

   local select_kind = string.format(
   'legendary.%s',
   type(item_kind) == 'string' and #item_kind > 0 and item_kind or 'items')

   local prompt = opts.select_prompt or require('legendary.config').select_prompt
   if type(prompt) == 'function' then
      prompt = (prompt)(select_kind)
   end

   local padding = formatter.compute_padding(items, current_mode, opts.formatter)
   local format_item = function(item)
      return formatter.format(item, current_mode, padding, opts.formatter)
   end

   vim.ui.select(items, {
      prompt = vim.trim((prompt) or ''),
      kind = select_kind,
      format_item = format_item,
   }, function(selected)
      if not selected then
         return
      end



      if require('legendary.config').most_recent_item_at_top then
         last_used_item = vim.tbl_extend('force', {}, selected)
      end


      vim.schedule(function()
         require('legendary.executor').try_execute(
         selected,
         current_buf,
         visual_selection,
         current_mode,
         cursor_position)

      end)
   end)
end

return M
