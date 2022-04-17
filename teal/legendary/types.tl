-- `unpack` is a global in neovim
global unpack = ((_G as table).unpack or table.unpack) as function(table): any...

global enum LegendaryKind
   'legendary.keymap'
   'legendary.keymap.builtin'
   'legendary.command'
   'legendary.command.builtin'
   'legendary.augroup'
   'legendary.autocmd'
end

global record LegendaryModeMappingOpts
   {string | function(marks: table | nil): nil}
   opts: table | nil
end

global record LegendaryModeMapping
   n: string | function(marks: table | nil): nil | LegendaryModeMappingOpts
   v: string | function(marks: table | nil): nil | LegendaryModeMappingOpts
   x: string | function(marks: table | nil): nil | LegendaryModeMappingOpts
   c: string | function(marks: table | nil): nil | LegendaryModeMappingOpts
   s: string | function(marks: table | nil): nil | LegendaryModeMappingOpts
   t: string | function(marks: table | nil): nil | LegendaryModeMappingOpts
   i: string | function(marks: table | nil): nil | LegendaryModeMappingOpts
end

--- A legendary keymap
--- Note that the first element will *always*
--- be a string, but I can't express that in
--- the Teal type system
global record LegendaryKeymap
   {string | function(marks: table | nil): nil | LegendaryModeMapping | nil}
   mode: string | {string}
   description: string
   opts: table
   kind: LegendaryKind
   id: integer
   unfinished: boolean | nil
end

--- A legendary command
--- Note that the first element will *always*
--- be a string, but I can't express that in
--- the Teal type system
global record LegendaryCommand
   {string | function | nil}
   description: string
   opts: {string: any}
   kind: LegendaryKind
   id: integer
   unfinished: boolean | nil
end

--- A legendary autocmd
--- Note that the first element will *always*
--- be a string, but I can't express that in
--- the Teal type system
global record LegendaryAutocmd
   {string | function | nil}
   description: string
   opts: table
   kind: LegendaryKind
   id: integer
end

--- A legendary augroup
global record LegendaryAugroup
   name: string
   clear: boolean
   {LegendaryAutocmd}
end

--- Can be any of the legendary table types
global record LegendaryItem
   id: integer
   kind: LegendaryKind
   description: string | nil
   opts: table
end

global type LegendaryItemFilter = function(item: LegendaryItem): boolean

global record LegendaryWhichKeys
   mappings: {table}
   opts: table
end

global enum LegendaryScratchpadDisplay
   'float'
   'print'
end

global record LegendaryScratchpadConfig
   display_results: LegendaryScratchpadDisplay
end

global record LegendaryConfig
   include_builtin: boolean
   include_legendary_cmds: boolean
   select_prompt: string | function(string): string
   formatter: function(LegendaryItem): {string}
   most_recent_item_at_top: boolean
   keymaps: {LegendaryKeymap}
   commands: {LegendaryCommand}
   autocmds: {LegendaryAugroup}
   auto_register_which_key: boolean
   which_key: LegendaryWhichKeys
   scratchpad: LegendaryScratchpadConfig
   setup: function(new_config: table): LegendaryConfig
end

local M = {}

function M.validate_config(config: LegendaryConfig)
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

function M.validate_keymap(keymap: LegendaryKeymap)
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

function M.validate_command(command: LegendaryCommand)
   vim.validate({
      ['1'] = { command[1], 'string' },
      ['2'] = { command[2], { 'string', 'function' }, true },
      description = { command.description, 'string', true },
      opts = { command.opts, 'table', true },
      kind = { command.kind, 'string' },
      id = { command.id, 'number' },
   })
end

function M.validate_autocmd(autocmd: LegendaryAutocmd)
   vim.validate({
      ['1'] = { autocmd[1], { 'string', 'table' } },
      ['2'] = { autocmd[2], { 'string', 'function' }, true },
      description = { autocmd.description, 'string', true },
      opts = { autocmd.opts, 'table', true },
      kind = { autocmd.kind, 'string' },
      id = { autocmd.id, 'number' },
   })
end

function M.validate_augroup(au: LegendaryAugroup)
 -- the autocmds inside get validated by LegendaryItem.validate at bind time
 vim.validate({
   name = { au.name, 'string' },
   clear = { au.clear, 'boolean', true },
 })
end

return M
