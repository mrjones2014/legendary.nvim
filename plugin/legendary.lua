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

local opts = {
  desc = 'Find keymaps and commands with vim.ui.select()',
  nargs = 1,
  complete = command_completion,
}

vim.api.nvim_add_user_command('Legendary', find, opts)
