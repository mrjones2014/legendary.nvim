local Config = require('legendary-v2.config')
local State = require('legendary-v2.state')
local Ui = require('legendary-v2.ui')
local Executor = require('legendary-v2.executor')
local Keymap = require('legendary-v2.types.keymap')
local Command = require('legendary-v2.types.command')
local Augroup = require('legendary-v2.types.augroup')
local Autocmd = require('legendary-v2.types.autocmd')
local Function = require('legendary-v2.types.function')

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

return M
