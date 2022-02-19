if not vim.keymap or not vim.keymap.set then
  require('legendary.util').notify('Sorry, legendary.nvim requires Neovim 0.7.0 or higher!')
  return
end

local function trim(s)
  return (string.gsub(s, '^%s*(.-)%s*$', '%1'))
end

local function find(opts)
  if not opts or not opts.args then
    return require('legendary').find()
  end

  if trim(opts.args:lower()) == 'keymaps' then
    return require('legendary').find('keymaps')
  end

  if trim(opts.args:lower()) == 'commands' then
    return require('legendary').find('commands')
  end

  require('legendary').find()
end

local function command_completion(arg_lead)
  if arg_lead and trim(arg_lead):sub(1, 1):lower() == 'k' then
    return { 'keymaps' }
  end

  if arg_lead and trim(arg_lead):sub(1, 1):lower() == 'c' then
    return { 'commands' }
  end

  return { 'keymaps', 'commands' }
end

vim.api.nvim_add_user_command('Legendary', find, {
  desc = 'Find keymaps and commands with vim.ui.select()',
  nargs = 1,
  complete = command_completion,
})

vim.api.nvim_add_user_command('LegendaryScratch', function()
  require('legendary.scratchpad').create_scratchpad_buffer()
end, {
  desc = 'Create a Lua scratchpad buffer to help develop commands and keymaps',
})

vim.api.nvim_add_user_command('LegendaryEvalLine', function()
  if vim.bo.ft ~= 'lua' then
    vim.api.nvim_err_write("Filetype must be 'lua' or 'LegendaryEditor' to eval lua code")
    return
  end
  require('legendary.scratchpad').lua_eval_current_line()
end, {
  desc = 'Eval the current line as Lua',
})

vim.api.nvim_add_user_command('LegendaryEvalLines', function(range)
  if vim.bo.ft ~= 'lua' then
    vim.api.nvim_err_write("Filetype must be 'lua' or 'LegendaryEditor' to eval lua code")
    return
  end
  require('legendary.scratchpad').lua_eval_line_range(range.line1, range.line2)
end, {
  desc = 'Eval lines selected in visual mode as Lua',
  range = true,
})

vim.api.nvim_add_user_command('LegendaryEvalBuf', function()
  require('legendary.scratchpad').lua_eval_buf()
end, {
  desc = 'Eval the whole buffer as Lua',
})
