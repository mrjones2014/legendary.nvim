# Lua API

You can also manually bind new items after you've already called `require('legendary').setup()`.
This can be useful for things like binding language-specific keyaps in the LSP `on_attach` function.

The main API functions are described below. To see full API documentation, run `:LegendaryApi`.

## Binding Keymaps, Commands, Autocmds, and Functions

```lua
-- bind a single keymap
require('legendary').keymap(keymap)
-- bind a list of keymaps
require('legendary').keymaps({
  -- your keymaps here
})

-- bind a single command
require('legendary').command(command)
-- bind a list of commands
require('legendary').commands({
  -- your commands here
})

-- bind a single function table
require('legendary').bind_function(fn_tbl)
-- bind a list of functions
require('legendary').bind_functions({
  -- your function tables here
})

-- bind a single augroup/autocmds
require('legendary').autocmd(augroup_or_autocmd)
-- bind a list of augroups/autocmds
require('legendary').autocmds({
  -- your augroups and autocmds here
})

-- search keymaps, commands, functions, and autocmds
require('legendary').find()
-- search keymaps
require('legendary').find({ filters = { require('legendary.filters').keymaps() } })
-- search commands
require('legendary').find({ filters = { require('legendary.filters').commands() } })
-- search functions
require('legendary').find({ filters = { require('legendary.filters').funcs() } })
-- search autocmds
require('legendary').find({ filters = { require('legendary.filters').autocmds() } })

-- filter keymaps by current mode
require('legendary').find({
  filters = { require('legendary.filters').current_mode() },
})

-- find only keymaps, and filter by current mode
require('legendary').find({
  filters = {
    require('legendary.filters').current_mode(),
    require('legendary.filters').keymap(),
  },
})
-- filter keymaps by normal mode
require('legendary').find({
  filters = require('legendary.filters').mode('n')
})
-- filter keymaps by normal mode and that start with <leader>
require('legendary').find({
  filters = {
    require('legendary.filters').mode('n'),
    function(item)
      return require('legendary.toolbox').is_keymap(item) and vim.startswith(item[1], '<leader>')
    end
  }
})
```

## Converting Keymaps From Vimscript

Keymaps can be parsed from Vimscript commands (e.g. `vnoremap <silent> <leader>f :SomeCommand<CR>`).

```lua
-- Function signature
require('legendary.data.keymap'):from_vimscript(vimscript_str, description)
-- For example
require('legendary.data.keymap'):from_vimscript(':vnoremap <silent> <leader>f :SomeCommand<CR>', 'Description of my keymap')
-- Returns the following table
{
  '<leader>f',
  ':SomeCommand<CR>',
  description = 'Description of my keymap',
  mode = 'v',
  opts = {
    silent = true,
    remap = false,
  },
}
```
