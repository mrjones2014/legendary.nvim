local _tl_compat; if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then local p, m = pcall(require, 'compat53.module'); if p then _tl_compat = m end end; local table = _tl_compat and _tl_compat.table or table; local _tl_table_unpack = unpack or table.unpack
unpack = ((_G).unpack or _tl_table_unpack)

 LegendaryModeMappingOpts = {}




 LegendaryModeMapping = {}













 LegendaryKeymap = {}













 LegendaryCommand = {}












 LegendaryAutocmd = {}








 LegendaryAugroup = {}






 LegendaryItem = {}





 LegendaryWhichKeys = {}





 LegendaryScratchpadDisplay = {}




 LegendaryScratchpadConfig = {}



 LegendaryConfig = {}














local M = {}

function M.validate_config(config)
   vim.validate({
      include_builtin = { config.include_builtin, 'boolean', true },
      include_legendary_cmds = { config.include_legendary_cmds, 'boolean', true },
      select_prompt = { config.select_prompt, { 'string', 'function' }, true },
      formatter = { config.formatter, 'function', true },
      most_recent_item_at_top = { config.most_recent_item_at_top, 'boolean', true },
      keymaps = { config.keymaps, 'table', true },
      commands = { config.keymaps, 'table', true },
      autocmds = { config.keymaps, 'table', true },
      auto_register_which_key = { config.auto_register_which_key, 'boolean', true },
   })
end

function M.validate_keymap(keymap)
   vim.validate({
      ['1'] = { keymap[1], 'string' },
      ['2'] = { keymap[2], { 'string', 'function', 'table' }, true },
      description = { keymap.description, 'string', true },
      mode = { keymap.mode, { 'string', 'table' }, true },
      opts = { keymap.opts, 'table', true },
      kind = { keymap.kind, 'string' },
      id = { keymap.id, 'number' },
   })
end

function M.validate_command(command)
   vim.validate({
      ['1'] = { command[1], 'string' },
      ['2'] = { command[2], { 'string', 'function' }, true },
      description = { command.description, 'string', true },
      opts = { command.opts, 'table', true },
      kind = { command.kind, 'string' },
      id = { command.id, 'number' },
   })
end

function M.validate_autocmd(autocmd)
   vim.validate({
      ['1'] = { autocmd[1], { 'string', 'table' } },
      ['2'] = { autocmd[2], { 'string', 'function' }, true },
      description = { autocmd.description, 'string', true },
      opts = { autocmd.opts, 'table', true },
      kind = { autocmd.kind, 'string' },
      id = { autocmd.id, 'number' },
   })
end

function M.validate_augroup(au)

   vim.validate({
      name = { au.name, 'string' },
      clear = { au.clear, 'boolean', true },
   })
end

return M
