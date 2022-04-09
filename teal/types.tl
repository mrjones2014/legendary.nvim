global type LegendaryModeMappingOpts = record
   ['1']: string | function(): nil
   opts: table | nil
end

global type LegendaryModeMapping = record
   n: string | function(): nil | LegendaryModeMappingOpts
   v: string | function(): nil | LegendaryModeMappingOpts
   x: string | function(): nil | LegendaryModeMappingOpts
   c: string | function(): nil | LegendaryModeMappingOpts
   s: string | function(): nil | LegendaryModeMappingOpts
   t: string | function(): nil | LegendaryModeMappingOpts
end

--- A legendary keymap
global type LegendaryKeymap = record
   ['1']: string
   ['2']: string | function(): nil | LegendaryModeMapping | nil
   mode: string | {string}
   description: string
   opts: table
   kind: string
   id: number
end

--- A legendary command
global type LegendaryCommand = record
   ['1']: string
   ['2']: string | function | nil
   description: string
   opts: table
   kind: string
   id: number
end

--- A legendary autocmd
global type LegendaryAutocmd = record
   ['1']: string
   ['2']: string | function | nil
   description: string
   opts: table
   kind: string
   id: number
end

--- A legendary augroup
global type LegendaryAugroup = record
   name: string
   {LegendaryAutocmd}
end

--- Can be any of the legendary table types
global type LegendaryItem = record
   kind: string
end

global type LegendaryWhichKeys = record
end

global type LegendaryScratchpadDisplay = enum
   'float'
end

global type LegendaryScratchpadConfig = record
   display_results: LegendaryScratchpadDisplay
end

global type LegendaryConfig = record
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
      [1] = { keymap[1], 'string' },
      [2] = { keymap[2], { 'string', 'function', 'table' }, true },
      description = { keymap.description, 'string', true },
      mode = { keymap.mode, { 'string', 'table' }, true },
      opts = { keymap.opts, 'table', true },
      kind = { keymap.kind, 'string' },
      id = { keymap.id, 'number' },
   })
end

function M.validate_command(command: LegendaryCommand)
   vim.validate({
      [1] = { command[1], 'string' },
      [2] = { command[2], { 'string', 'function' }, true },
      description = { command.description, 'string', true },
      opts = { command.opts, 'table', true },
      kind = { command.kind, 'string' },
      id = { command.id, 'number' },
   })
end

function M.validate_autocmd(autocmd: LegendaryAutocmd)
   vim.validate({
      [1] = { autocmd[1], 'string' },
      [2] = { autocmd[2], { 'string', 'function' }, true },
      description = { autocmd.description, 'string', true },
      opts = { autocmd.opts, 'table', true },
      kind = { autocmd.kind, 'string' },
      id = { autocmd.id, 'number' },
   })
end

function M.validate_augroup(au: LegendaryAugroup)
 -- the autocmds inside get validated by LegendaryItem.validate at bind time
 -- diagnostics see vim.validate() as not accepting any parameters for some reason
 ---@diagnostic disable-next-line: redundant-parameter
 vim.validate({
   name = { au.name, 'string' },
   clear = { au.clear, 'boolean', true },
 })
end

return M
