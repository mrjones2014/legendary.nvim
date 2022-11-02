local Config = require('legendary-v2.config')
local State = require('legendary-v2.state')
local Ui = require('legendary-v2.ui')
local Executor = require('legendary-v2.executor')
local Keymap = require('legendary-v2.types.keymap')
local Command = require('legendary-v2.types.command')
local Augroup = require('legendary-v2.types.augroup')
local Autocmd = require('legendary-v2.types.autocmd')
local Function = require('legendary-v2.types.function')

---@param parser LegendaryItem
---@return fun(items:table[])
local function build_parser_func(parser)
  return function(items)
    if not vim.tbl_islist(items) then
      error(string.format('Expected list, got ', type(items)))
      return
    end

    State.items:add(vim.tbl_map(function(item)
      return parser:parse(item):apply()
    end, items))
  end
end

local M = {}

function M.setup(cfg)
  Config.setup(cfg)

  State.items:add(vim.tbl_map(function(keymap)
    return Keymap:parse(keymap)
  end, Config.keymaps))

  State.items:add(vim.tbl_map(function(command)
    return Command:parse(command)
  end, Config.commands))

  State.items:add(vim.tbl_map(function(augroup_or_autocmd)
    if type(augroup_or_autocmd.name) == 'string' and #augroup_or_autocmd.name > 0 then
      return Augroup:parse(augroup_or_autocmd)
    else
      return Autocmd:parse(augroup_or_autocmd)
    end
  end, Config.autocmds))

  State.items:add(vim.tbl_map(function(func)
    return Function:parse(func)
  end, Config.functions))

  -- apply items
  vim.tbl_map(function(item)
    item:apply()
  end, State.items:get())

  -- Add builtins after apply since they don't need applied
  if Config.include_builtin then
    -- inline require to avoid the cost of importing
    -- this somewhat large data file if not needed
    local Builtins = require('legendary-v2.builtins')

    State.items:add(vim.tbl_map(function(keymap)
      return Keymap:parse(keymap)
    end, Builtins.builtin_keymaps))

    State.items:add(vim.tbl_map(function(command)
      return Command:parse(command)
    end, Builtins.builtin_commands))
  end
end

---Find items using vim.ui.select()
---@param opts LegendaryFindOpts
function M.find(opts)
  local context = Executor.build_pre_context()

  Ui.select(opts, function(selected)
    if not selected then
      return
    end

    Executor.exec_item(selected, context)
  end)
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

---@diagnostic enable: undefined-doc-param

---Bind a *list of* autocmds and/or augroups
---@param aus (Autocmd|Augroup)[]
function M.autocmds(aus)
  if not vim.tbl_islist(aus) then
    error(string.format('Expected list, got %s.\n    %s', type(aus), vim.inspect(aus)))
    return
  end

  State.items:add(vim.tbl_map(function(augroup_or_autocmd)
    if type(augroup_or_autocmd.name) == 'string' and #augroup_or_autocmd.name > 0 then
      return Augroup:parse(augroup_or_autocmd)
    else
      return Autocmd:parse(augroup_or_autocmd)
    end
  end, aus))
end

---Bind a *single autocmd/augroup*
---@param au Autocmd|Augroup
function M.autocmd(au)
  M.autocmds({ au })
end

return M
