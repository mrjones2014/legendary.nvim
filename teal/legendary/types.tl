---@mod legendary.types require('legendary.types')

-- `unpack` is a global in neovim
global unpack = ((_G as table).unpack or table.unpack) as function(table): any...

---@class LegendaryKind Enum containing the valid `kind` values
global enum LegendaryKind
   'legendary.keymap'
   'legendary.keymap.builtin'
   'legendary.command'
   'legendary.command.builtin'
   'legendary.augroup'
   'legendary.autocmd'
end

---@class LegendaryModeMappingOpts The value of a per-mode mapping with per-mode opts
---@field [1] string | function(table | nil): nil
---@field opts table | nil
global record LegendaryModeMappingOpts
   {string | function(marks: table | nil): nil}
   opts: table | nil
end

---@class LegendaryModeMapping The value of a per-mode mapping
---@field n string | (function(table | nil): nil) | LegendaryModeMappingOpts
---@field v string | (function(table | nil): nil) | LegendaryModeMappingOpts
---@field x string | (function(table | nil): nil) | LegendaryModeMappingOpts
---@field c string | (function(table | nil): nil) | LegendaryModeMappingOpts
---@field s string | (function(table | nil): nil) | LegendaryModeMappingOpts
---@field t string | (function(table | nil): nil) | LegendaryModeMappingOpts
---@field i string | (function(table | nil): nil) | LegendaryModeMappingOpts
global record LegendaryModeMapping
   n: string | function(marks: table | nil): nil | LegendaryModeMappingOpts
   v: string | function(marks: table | nil): nil | LegendaryModeMappingOpts
   x: string | function(marks: table | nil): nil | LegendaryModeMappingOpts
   c: string | function(marks: table | nil): nil | LegendaryModeMappingOpts
   s: string | function(marks: table | nil): nil | LegendaryModeMappingOpts
   t: string | function(marks: table | nil): nil | LegendaryModeMappingOpts
   i: string | function(marks: table | nil): nil | LegendaryModeMappingOpts
end

---@class LegendaryKeymap A legendary keymap. You can add keymaps to the finder without binding them by omitting the second list element.
---@field [1] string
---@field [2] string | (function(table | nil): nil) | LegendaryModeMapping | nil
---@field mode string | {string}
---@field description string | nil
---@field opts table | nil
---@field kind string
---@field unfinished boolean | nil
global record LegendaryKeymap
   {string | function(marks: table | nil): nil | LegendaryModeMapping | nil}
   mode: string | {string}
   description: string
   opts: table
   kind: LegendaryKind
   id: integer
   unfinished: boolean | nil
end

---@class LegendaryCommand A legendary command. You can add commands to the finder without binding them by omitting the second list element.
---@field [1] string
---@field [2] string | function | nil
---@field mode string | {string}
---@field description string | nil
---@field opts table | nil
---@field kind string
---@field unfinished boolean | nil
global record LegendaryCommand
   {string | function | nil}
   description: string
   opts: {string: any}
   kind: LegendaryKind
   id: integer
   unfinished: boolean | nil
end

---@class LegendaryAutocmd A legendary autocmd
---@field [1] string
---@field [2] string | function | nil
---@field description string | nil
---@field opts table | nil
---@field kind string
global record LegendaryAutocmd
   {string | function | nil}
   description: string
   opts: table
   kind: LegendaryKind
   id: integer
end

---@class LegendaryAugroup A legendary augroup
---@field name string
---@field clear boolean
---@field {LegendaryAutocmd}
global record LegendaryAugroup
   name: string
   clear: boolean
   {LegendaryAutocmd}
end

---@class LegendaryItem Can be any of the legendary table types
---@field description string | nil
---@field opts table | nil
---@field kind string
global record LegendaryItem
   id: integer
   kind: LegendaryKind
   description: string | nil
   opts: table
end

---@class LegendaryItemFilter A type alias for
--- `function(item: LegendaryItem): boolean`
global type LegendaryItemFilter = function(item: LegendaryItem): boolean

---@class LegendaryFormatter A type alias for
--- `function(item: LegendaryItem): {string}` used for formatting items for the finder
global type LegendaryFormatter = function(LegendaryItem): {string}

---@class Options accepted by `require('legendary').find()`
---@field kind 'keymaps' | 'commands' | 'autocmds' | nil
---@field filters {LegendaryItemFilter} | nil
---@field formatter LegendaryFormatter | nil
global record LegendaryFindOpts
   kind: string | nil
   filters: {LegendaryItemFilter} | nil
   formatter: LegendaryFormatter
end

global record LegendaryWhichKeys
   mappings: {table}
   opts: table
   do_binding: boolean
end

---@class LegendaryScratchpadDisplay enum containing value options for config.scratchpad.display_results
global enum LegendaryScratchpadDisplay
   'float'
   'print'
end

---@class LegendaryScratchpadConfig The config table for the Legendary scratchpad
global record LegendaryScratchpadConfig
   display_results: LegendaryScratchpadDisplay
end

---@class LegendaryConfig Configuration table for legendary
---@field include_builtin boolean
---@field include_legendary_cmds boolean
---@field select_prompt string | function(string): string
---@field formatter function(LegendaryItem): {string}
---@field most_recent_item_at_top boolean
---@field keymaps {LegendaryKeymap}
---@field commands {LegendaryCommand}
---@field autocmds {LegendaryAugroup}
---@field auto_register_which_key boolean
---@field which_key LegendaryWhichKeys
---@field scratchpad LegendaryScratchpadConfig
---@field setup function(new_config: table): LegendaryConfig
global record LegendaryConfig
   include_builtin: boolean
   include_legendary_cmds: boolean
   select_prompt: string | function(string): string
   formatter: LegendaryFormatter
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

--- Validator function for configuration table
---@param config LegendaryConfig
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

--- Validator function for LegendaryKeymaps
---@param keymap LegendaryKeymap
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

--- Validator function for LegendaryCommands
---@param command LegendaryCommand
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

--- Validator function for LegendaryAutocmds
---@param autocmd LegendaryAutocmd
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

--- Validator function for LegendaryAugroups
--- Note: does NOT validate the LegendaryAutocmds inside it
---@param au LegendaryAugroup
function M.validate_augroup(au: LegendaryAugroup)
 -- the autocmds inside get validated by LegendaryItem.validate at bind time
 vim.validate({
   name = { au.name, 'string' },
   clear = { au.clear, 'boolean', true },
 })
end

return M
