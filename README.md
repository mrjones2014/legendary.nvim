# Legendary

Define your keymaps, commands, and autocommands as simple Lua tables, building a legend at the same time.

<!-- panvimdoc-ignore-start -->

![demo](https://user-images.githubusercontent.com/8648891/160112850-5fbbf327-309c-4bac-ad6b-df217127d886.gif)
<sup>Theme used in recording is [lighthaus.nvim](https://github.com/mrjones2014/lighthaus.nvim). The finder UI is handled by [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) via [dressing.nvim](https://github.com/stevearc/dressing.nvim). See [Prerequisites](#prerequisites) for details.</sup>

<!-- START doctoc -->

<!-- END doctoc -->

<!-- panvimdoc-ignore-end -->

## Features

- Define your keymaps, commands, and `augroup`/`autocmd`s as simple Lua tables, then bind them with `legendary.nvim`
- Integration with [which-key.nvim](https://github.com/folke/which-key.nvim), use your existing `which-key.nvim` tables with `legendary.nvim`
- Uses `vim.ui.select()` so it can be hooked up to a fuzzy finder using something like [dressing.nvim](https://github.com/stevearc/dressing.nvim) for a VS Code command palette like interface
- Execute normal, insert, and visual mode keymaps, commands, and autocommands, when you select them
- Show your most recently executed keymap, command, or autocmd at the top when triggered via `legendary.nvim` (can be disabled via config)
- Buffer-local keymaps, commands, and autocmds only appear in the finder for the current buffer
- Help execute commands that take arguments by prefilling the command line instead of executing immediately
- Search built-in keymaps and commands along with your user-defined keymaps and commands (may be disabled in config). Notice some missing? Comment on [this discussion](https://github.com/mrjones2014/legendary.nvim/discussions/89) or submit a PR!
- A `legendary.helpers` module to help create lazily-evaluated keymaps and commands. Have an idea for a new helper? Comment on [this discussion](https://github.com/mrjones2014/legendary.nvim/discussions/90) or submit a PR!

## Prerequisites

- Neovim 0.7.0+; specifically, this plugin depends on the following APIs:
  - `vim.keymap.set`
  - `vim.api.nvim_create_augroup`
  - `vim.api.nvim_create_autocmd`
- (Optional) A `vim.ui.select()` handler; this provides the UI for the finder.
  - I recommend [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) paired with [dressing.nvim](https://github.com/stevearc/dressing.nvim).

## Installation

With `packer.nvim`:

```lua
use({'mrjones2014/legendary.nvim'})
```

With `vim-plug`:

```VimL
Plug "mrjones2014/legendary.nvim"
```

## Usage

To trigger the finder for your configured keymaps, commands, and `augroup`/`autocmd`s:

Lua:

```lua
-- search keymaps, commands, and autocmds
require('legendary').find()
-- search keymaps
require('legendary').find('keymaps')
-- search commands
require('legendary').find('commands')
-- search autocmds
require('legendary').find('autocmds')
```

Vim commands:

```VimL
" search keymaps, commands, and autocmds
:Legendary

" search keymaps
:Legendary keymaps

" search commands
:Legendary commands

" search autocmds
:Legendary autocmds
```

In Lua, you can also specify filters in the second argument. It can be either a function, or a list of functions,
with the signature `function(item: LegendaryItem): boolean`. There are some pre-made filters in the `legendary.filters`
module.

```lua
-- filter keymaps by current mode
require('legendary').find(nil, require('legendary.filters').current_mode())
-- filter keymaps by normal mode
require('legendary').find(nil, require('legendary.filters').mode('n'))
-- show only keymaps and filter by normal mode
require('legendary').find('keymaps', require('legendary.filters').mode('n'))
-- filter keymaps by normal mode and that start with <leader>
require('legendary').find(nil, {
  require('legendary.filters').mode('n'),
  function(item)
    if not string.find(item.kind, 'keymap') then
      return true
    end

    return vim.startswith(item[1], '<leader>')
  end
})
```

## Configuration

Default configuration is shown below. For a detailed explanation of the structure for
keymap, command, and `augroup`/`autocmd` tables, see [Table Structures](#table-structures).

```lua
require('legendary').setup({
  -- Include builtins by default, set to false to disable
  include_builtin = true,
  -- Include the commands that legendary.nvim creates itself
  -- in the legend by default, set to false to disable
  include_legendary_cmds = true,
  -- Customize the prompt that appears on your vim.ui.select() handler
  -- Can be a string or a function that takes the `kind` and returns
  -- a string. See "Item Kinds" below for details. By default,
  -- prompt is 'Legendary' when searching all items,
  -- 'Legendary Keymaps' when searching keymaps,
  -- 'Legendary Commands' when searching commands,
  -- and 'Legendary Autocmds' when searching autocmds.
  select_prompt = nil,
  -- Optionally pass a custom formatter function. This function
  -- receives the item as a parameter and must return a table of
  -- non-nil string values for display. It must return the same
  -- number of values for each item to work correctly.
  -- The values will be used as column values when formatted.
  -- See function `get_default_format_values(item)` in
  -- `lua/legendary/formatter.lua` to see default implementation.
  formatter = nil,
  -- When you trigger an item via legendary.nvim,
  -- show it at the top next time you use legendary.nvim
  most_recent_item_at_top = true,
  -- Initial keymaps to bind
  keymaps = {
    -- your keymap tables here
  },
  -- Initial commands to bind
  commands = {
    -- your command tables here
  },
  -- Initial augroups and autocmds to bind
  autocmds = {
    -- your autocmd tables here
  },
  which_key = {
    -- you can put which-key.nvim tables here,
    -- or alternatively have them auto-register,
    -- see section on which-key integration
    mappings = {},
    opts = {},
    -- controls whether legendary.nvim actually binds they keymaps,
    -- or if you want to let which-key.nvim handle the bindings.
    -- if not passed, true by default
    do_binding = {},
  },
  -- Automatically add which-key tables to legendary
  -- see "which-key.nvim Integration" below for more details
  auto_register_which_key = true,
  -- settings for the :LegendaryScratch command
  scratchpad = {
    -- configure how to show results of evaluated Lua code,
    -- either 'print' or 'float'
    -- Pressing q or <ESC> will close the float
    display_results = 'float',
  },
})
```

### `which-key.nvim` Integration

Already a `which-key.nvim` user? Use your existing `which-key.nvim` tables with `legendary.nvim`!

There's a couple ways you can choose to do it:

```lua
-- automatically register which-key.nvim tables with legendary.nvim
-- when you register them with which-key.nvim.
-- `setup()` must be called before `require('which-key).register()`
require('legendary').setup()
-- now this will register them with both which-key.nvim and legendary.nvim
require('which-key').register(your_which_key_tables, your_which_key_opts)

-- or, pass them through setup() directly
require('legendary').setup({
  which_key = {
    mappings = your_which_key_tables,
    opts = your_which_key_opts,
    -- false if which-key.nvim handles binding them,
    -- set to true if you want legendary.nvim to handle binding
    -- the mappings; if not passed, true by default
    do_binding = false,
  },
})

-- or, if you'd prefer to manually register with legendary.nvim
require('legendary').setup({ auto_register_which_key = false })
require('which-key').register(your_which_key_tables, your_which_key_opts)
require('legendary').bind_whichkey(
  your_which_key_tables,
  your_which_key_opts,
  -- false if which-key.nvim handles binding them,
  -- set to true if you want legendary.nvim to handle binding
  -- the mappings; if not passed, true by default
  false,
)
```

## Table Structures

The tables for keymaps, commands, and `augroup`/`autocmd`s are all similar.

Descriptions can be specified either in the top-level `description` property
on each table, or inside the `opts` table as `opts.desc = 'Description goes here'`.

For
