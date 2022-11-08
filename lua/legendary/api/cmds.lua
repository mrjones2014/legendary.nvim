local Command = require('legendary.data.command')

local M = {}

M.cmds = vim.tbl_map(function(cmd)
  return Command:parse(cmd)
end, {
  {
    ':Legendary',
    function(opts)
      local l = require('legendary')
      local filters = require('legendary.filters')
      if not opts or not opts.args then
        l.find()
        return
      end

      if vim.trim((opts.args):lower()) == 'keymaps' then
        l.find({ filters = { filters.keymaps() } })
        return
      end

      if vim.trim((opts.args):lower()) == 'commands' then
        l.find({ filters = { filters.commands() } })
        return
      end

      if vim.trim((opts.args):lower()) == 'autocmds' then
        l.find({ filters = { filters.autocmds() } })
        return
      end

      if vim.trim((opts.args):lower()) == 'functions' then
        l.find({ filters = { filters.funcs() } })
        return
      end

      l.find()
    end,
    description = 'Find keymaps and commands with vim.ui.select()',
    opts = {
      nargs = '*',
      complete = function(arg_lead)
        if arg_lead and vim.trim(arg_lead):sub(1, 1):lower() == 'k' then
          return { 'keymaps' }
        end

        if arg_lead and vim.trim(arg_lead):sub(1, 1):lower() == 'c' then
          return { 'commands' }
        end

        if arg_lead and vim.trim(arg_lead):sub(1, 1):lower() == 'a' then
          return { 'autocmds' }
        end

        if arg_lead and vim.trim(arg_lead):sub(1, 1):lower() == 'f' then
          return { 'functions' }
        end

        return { 'keymaps', 'commands', 'autocmds', 'functions' }
      end,
    },
  },
  {
    ':LegendaryScratch',
    require('legendary.ui.scratchpad').open,
    description = 'Create a Lua scratchpad buffer to help develop commands and keymaps',
  },
  {
    ':LegendaryScratchToggle',
    require('legendary.ui.scratchpad').toggle,
    description = 'Toggle the legendary.nvim Lua scratchpad buffer',
  },
  {
    ':LegendaryEvalLine',
    function()
      if vim.bo.ft ~= 'lua' then
        vim.api.nvim_err_write("Filetype must be 'lua' to eval lua code")
        return
      end
      require('legendary.ui.scratchpad').lua_eval_current_line()
    end,
    description = 'Eval the current line as Lua',
  },
  {
    ':LegendaryEvalLines',
    function(range)
      if vim.bo.ft ~= 'lua' then
        vim.api.nvim_err_write("Filetype must be 'lua' to eval lua code")
        return
      end
      require('legendary.ui.scratchpad').lua_eval_range(range.line1, range.line2)
    end,
    description = 'Eval lines selected in visual mode as Lua',
    opts = {
      range = true,
    },
  },
  {
    ':LegendaryEvalBuf',
    require('legendary.ui.scratchpad').lua_eval_buf,
    description = 'Eval the whole buffer as Lua',
  },
  {
    ':LegendaryApi',
    function()
      vim.cmd(string.format('e %s/%s', vim.g.legendary_root_dir, 'doc/legendary-api.txt'))
      local buf_id = vim.api.nvim_get_current_buf()
      vim.api.nvim_buf_set_option(buf_id, 'filetype', 'help')
      vim.api.nvim_buf_set_option(buf_id, 'buftype', 'help')
      vim.api.nvim_buf_set_name(buf_id, string.format('Legendary API Docs [%s]', buf_id))
      vim.api.nvim_win_set_buf(0, buf_id)
      vim.api.nvim_buf_set_option(buf_id, 'modifiable', false)
    end,
    description = "Show Legendary's full API documentation",
  },
  {
    ':LegendaryDeprecated',
    function()
      require('legendary.deprecate').flush()
    end,
    description = 'Show legendary.nvim deprecation warning messages, if any',
  },
})

M.bind = function()
  vim.tbl_map(function(command)
    command:apply()
  end, M.cmds)
end

return M
