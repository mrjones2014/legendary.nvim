---@mod legendary

local Lazy = require('legendary.vendor.lazy')

---@type LegendaryConfig
local Config = Lazy.require_on_index('legendary.config')
---@type LegendaryState
local State = Lazy.require_on_index('legendary.data.state')
---@type LegendaryUi
local Ui = Lazy.require_on_exported_call('legendary.ui')
---@type Keymap
local Keymap = Lazy.require_on_exported_call('legendary.data.keymap')
---@type Command
local Command = Lazy.require_on_exported_call('legendary.data.command')
---@type Augroup
local Augroup = Lazy.require_on_exported_call('legendary.data.augroup')
---@type Autocmd
local Autocmd = Lazy.require_on_exported_call('legendary.data.autocmd')
---@type Function
local Function = Lazy.require_on_exported_call('legendary.data.function')
---@type ItemGroup
local ItemGroup = Lazy.require_on_exported_call('legendary.data.itemgroup')
---@type LegendaryLogger
local Log = Lazy.require_on_exported_call('legendary.log')

local Extensions = Lazy.require_on_exported_call('legendary.extensions')

---@param parser LegendaryItem
---@return fun(items:table[])
local function build_parser_func(parser)
  ---@param items table
  return function(items)
    if type(items.itemgroup) == 'string' then
      State.items:add({ ItemGroup:parse(items):apply() })
      return
    end

    local islist = vim.islist or vim.tbl_islist
    if not islist(items) then
      error(string.format('Expected list, got ', type(items)))
      return
    end

    State.items:add(vim.tbl_map(function(item)
      if type(item.itemgroup) == 'string' then
        return ItemGroup:parse(item):apply()
      end
      return parser:parse(item):apply()
    end, items))
  end
end

local M = {}

local lazy_loading_done = false
local function lazy_load_stuff()
  if lazy_loading_done then
    return
  end

  lazy_loading_done = true

  M.funcs(Config.funcs)

  if Config.include_builtin then
    -- inline require to avoid the cost of importing
    -- this somewhat large data file if not needed
    local Builtins = require('legendary.data.builtins')

    State.items:add(vim.tbl_map(function(keymap)
      return Command:parse(keymap, true)
    end, Builtins.get_commands()))

    State.items:add(vim.tbl_map(function(keymap)
      return Keymap:parse(keymap, true)
    end, Builtins.builtin_keymaps))

    State.items:add(vim.tbl_map(function(command)
      return Command:parse(command, true)
    end, Builtins.builtin_commands))
  end

  if Config.include_legendary_cmds then
    State.items:add(require('legendary.api.cmds').cmds)
  end
end

function M.setup(cfg)
  Config.setup(cfg)

  M.keymaps(Config.keymaps)
  M.commands(Config.commands)
  M.autocmds(Config.autocmds)
  M.itemgroups(Config.itemgroups)

  if #vim.tbl_keys(Config.extensions) > 0 then
    Extensions.load_all()
  end

  Log.trace('setup() parsed and applied all configuration.')
end

---Repeat execution of the previously selected item. By default, only executes if the previously used filters
---still return true.
---@param ignore_filters boolean|nil whether to ignore the filters used when selecting the item, default false
function M.repeat_previous(ignore_filters)
  require('legendary.api.executor').repeat_previous(ignore_filters)
end

---Find items using vim.ui.select()
---@param opts LegendaryFindOpts
---@overload fun()
function M.find(opts)
  lazy_load_stuff()
  Ui.select(opts)
end

---@diagnostic disable: undefined-doc-param
-- disable undefined-doc-param since we're dynamically generating these functions
-- but I still want them to be annotated

---Bind a *list of keymaps*
---@param keymaps table[]
M.keymaps = build_parser_func(Keymap)

---Bind a *single keymap*
---@param keymap table
function M.keymap(keymap)
  M.keymaps({ keymap })
end

---Bind a *list of commands*
---@param commands table[]
M.commands = build_parser_func(Command)

---Bind a *single command*
---@param command table
function M.command(command)
  M.commands({ command })
end

---Bind a *list of functions*
---@param functions table[]
M.funcs = build_parser_func(Function)

---Bind a *single function*
---@param function table
function M.func(func)
  M.funcs({ func })
end

---Bind a *list of item groups*
---@param itemgroup table[]
M.itemgroups = build_parser_func(ItemGroup)

---Bind a *single item group*
---@param itemgroup table
function M.itemgroup(itemgroup)
  M.itemgroups({ itemgroup })
end

---@diagnostic enable: undefined-doc-param

---Bind a *list of* autocmds and/or augroups
---@param aus table
function M.autocmds(aus)
  local islist = vim.islist or vim.tbl_islist
  if not islist(aus) then
    Log.error('Expected list, got %s.\n    %s', type(aus), vim.inspect(aus))
    return
  end

  for _, augroup_or_autocmd in ipairs(aus) do
    if type(augroup_or_autocmd.name) == 'string' and #augroup_or_autocmd.name > 0 then
      local autocmds = Augroup:parse(augroup_or_autocmd --[[@as Augroup]]):apply().autocmds
      State.items:add(autocmds)
    else
      -- Only add Autocmds to the list since Augroups can't be executed
      State.items:add({ Autocmd:parse(augroup_or_autocmd):apply() })
    end
  end
end

---Bind a *single autocmd/augroup*
---@param au table
function M.autocmd(au)
  M.autocmds({ au })
end

return M
