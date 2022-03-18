local M = {}

M.cmds = {
  {
    ':Legendary',
    function(opts)
      if not opts or not opts.args then
        return require('legendary').find()
      end

      if vim.trim(opts.args:lower()) == 'keymaps' then
        return require('legendary').find('legendary.keymap')
      end

      if vim.trim(opts.args:lower()) == 'commands' then
        return require('legendary').find('legendary.command')
      end

      if vim.trim(opts.args:lower()) == 'autocmds' then
        return require('legendary').find('legendary.autocmd')
      end

      require('legendary').find()
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

        return { 'keymaps', 'commands', 'autocmds' }
      end,
    },
  },
  {
    ':LegendaryScratch',
    require('legendary.scratchpad').create_scratchpad_buffer,
    description = 'Create a Lua scratchpad buffer to help develop commands and keymaps',
  },
  {
    ':LegendaryEvalLine',
    function()
      if vim.bo.ft ~= 'lua' then
        vim.api.nvim_err_write("Filetype must be 'lua' or 'LegendaryEditor' to eval lua code")
        return
      end
      require('legendary.scratchpad').lua_eval_current_line()
    end,
    description = 'Eval the current line as Lua',
  },
  {
    ':LegendaryEvalLines',
    function(range)
      if vim.bo.ft ~= 'lua' then
        vim.api.nvim_err_write("Filetype must be 'lua' or 'LegendaryEditor' to eval lua code")
        return
      end
      require('legendary.scratchpad').lua_eval_line_range(range.line1, range.line2)
    end,
    description = 'Eval lines selected in visual mode as Lua',
    opts = {
      range = true,
    },
  },
  {
    ':LegendaryEvalBuf',
    require('legendary.scratchpad').lua_eval_buf,
    description = 'Eval the whole buffer as Lua',
  },
}

--- Bind the Legendary commands.
--- Does not register them with legendary.
--- See M.register to register them with legendary.
function M.bind()
  vim.tbl_map(require('legendary.utils').set_command, M.cmds)
end

--- Register the Legendary commands with legendary.
--- Does not create/bind them. See M.bind
function M.register()
  local items = vim.deepcopy(M.cmds)
  vim.tbl_map(function(item)
    item[2] = nil
  end, items)
  require('legendary').bind_commands(items)
end

return M
