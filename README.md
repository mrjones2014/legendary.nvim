> [!NOTE]
> `legendary.nvim` is [looking for a new maintainer](https://github.com/mrjones2014/legendary.nvim/issues/505)!

<div align="center">

# `legendary.nvim`

[Features](#features) | [Prerequisites](#prerequisites) | [Installation](#installation) | [Quickstart](#quickstart) | [Configuration](#configuration)

</div>

Define your keymaps, commands, and autocommands as simple Lua tables, building a legend at the same time (like VS Code's Command Palette).

![demo gif](https://user-images.githubusercontent.com/8648891/200827633-7009f5f3-e126-491c-88bd-73a0287978c4.gif) \
<sup>Theme used in recording is [onedarkpro.nvim](https://github.com/olimorris/onedarkpro.nvim). The finder UI is handled by [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) via [dressing.nvim](https://github.com/stevearc/dressing.nvim). See [Prerequisites](#prerequisites) for details.</sup>

**Table of Contents**

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Quickstart](#quickstart)
- [Configuration](#configuration)
  - [Troubleshooting Frecency Sort](#troubleshooting-frecency-sort)
- [Keymap Development Utilities](./doc/MAPPING_DEVELOPMENT.md)
- [Lua API](./doc/API.md)
- [Extensions](./doc/EXTENSIONS.md)
- [Table Structures](./doc/table_structures/README.md)
  - [Keymaps](./doc/table_structures/KEYMAPS.md)
  - [Commands](./doc/table_structures/COMMANDS.md)
  - [Functions](./doc/table_structures/FUNCTIONS.md)
  - [`augroup`/`autocmd`s](./doc/table_structures/AUTOCMDS.md)

## Features

- Define your keymaps, commands, `augroup`/`autocmd`s, and even arbitrary Lua functions to run on the fly, as simple Lua tables, then bind them with `legendary.nvim`
- Integration with [which-key.nvim](https://github.com/folke/which-key.nvim), use your existing `which-key.nvim` tables with `legendary.nvim` (see [extensions](./doc/EXTENSIONS.md#which-keynvim))
- Integration with [lazy.nvim](https://github.com/folke/lazy.nvim), automatically load keymaps defined via `lazy.nvim`'s `keys` property on plugin specs (see [extensions](./doc/EXTENSIONS.md#lazynvim))
- Execute normal, insert, and visual mode keymaps, commands, autocommands, and Lua functions when you select them
- Show your most recently executed items at the top when triggered via `legendary.nvim` (can be disabled via config)
- Uses `vim.ui.select()` so it can be hooked up to a fuzzy finder using something like [dressing.nvim](https://github.com/stevearc/dressing.nvim) for a VS Code command palette like interface
- Buffer-local keymaps, commands, functions and autocmds only appear in the finder for the current buffer
- Help execute commands that take arguments by prefilling the command line instead of executing immediately
- Search built-in keymaps and commands along with your user-defined keymaps and commands (may be disabled in config). Notice some missing? Comment on [this discussion](https://github.com/mrjones2014/legendary.nvim/discussions/89) or submit a PR!
- A `legendary.toolbox` module to help create lazily-evaluated keymaps and commands, and item filter. Have an idea for a new helper? Comment on [this discussion](https://github.com/mrjones2014/legendary.nvim/discussions/90) or submit a PR!
- Sort by [frecency](https://en.wikipedia.org/wiki/Frecency), a combined measure of how frequently and how recently you've used an item from the picker
- A parser to convert Vimscript keymap commands (e.g. `vnoremap <silent> <leader>f :SomeCommand<CR>`) to `legendary.nvim` keymap tables (see [Converting Keymaps From Vimscript](./doc/API.md#converting-keymaps-from-vimscript))
- Anonymous mappings; show mappings/commands in the finder without having `legendary.nvim` handle creating them
- Extensions to automatically load keymaps and commands from other plugins

## Prerequisites

- (Optional) A `vim.ui.select()` handler; this provides the UI for the finder.
  - I recommend [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) paired with [dressing.nvim](https://github.com/stevearc/dressing.nvim).

## Installation

This project uses git tags to adhere to [Semantic Versioning](https://semver.org/). To check the latest
version, see the [git tag list](https://github.com/mrjones2014/legendary.nvim/tags).

With `lazy.nvim`:

```lua
-- to use a version
{
  'mrjones2014/legendary.nvim',
  version = 'v2.13.9',
  -- since legendary.nvim handles all your keymaps/commands,
  -- its recommended to load legendary.nvim before other plugins
  priority = 10000,
  lazy = false,
  -- sqlite is only needed if you want to use frecency sorting
  -- dependencies = { 'kkharji/sqlite.lua' }
}
-- or, to get rolling updates
{
  'mrjones2014/legendary.nvim',
  -- since legendary.nvim handles all your keymaps/commands,
  -- its recommended to load legendary.nvim before other plugins
  priority = 10000,
  lazy = false,
  -- sqlite is only needed if you want to use frecency sorting
  -- dependencies = { 'kkharji/sqlite.lua' }
}
```

With `vim-plug`:

```VimL
" if you want to use frecency sorting, sqlite is also needed
Plug "kkharji/sqlite.lua"

" to use a version
Plug "mrjones2014/legendary.nvim", { 'tag': 'v2.1.0' }
" or, to get rolling updates
Plug "mrjones2014/legendary.nvim"
```

## Quickstart

If you use [lazy.nvim](https://github.com/folke/lazy.nvim) for your plugin manager, `legendary.nvim` can automatically
register keymaps defined via the `keys` property of `lazy.nvim` plugin specs. This lets you keep your plugin-specific
keymaps where you define the plugin, and `legendary.nvim` automatically detects them. For example:

```lua
-- in a plugin spec:
{
  'folke/flash.nvim',
  keys = {
    {
      's',
      function()
        require('flash').jump()
      end,
      mode = { 'n', 'x', 'o' },
      desc = 'Jump forwards',
    },
    {
      'S',
      function()
        require('flash').jump({ search = { forward = false } })
      end,
      mode = { 'n', 'x', 'o' },
      desc = 'Jump backwards',
    },
  },
}

-- where you set up legendary.nvim
-- now the keymaps from the `flash.nvim` plugin spec will be automatically loaded
require('legendary').setup({ extensions = { lazy_nvim = true } })
```

Otherwise, register keymaps, commands, autocmds, and functions through setup, including
opting into _extensions_ which can automatically load keymaps and commands from other plugins:

```lua
require('legendary').setup({
  keymaps = {
    -- map keys to a command
    { '<leader>ff', ':Telescope find_files', description = 'Find files' },
    -- map keys to a function
    {
      '<leader>h',
      function()
        print('hello world!')
      end,
      description = 'Say hello',
    },
    -- Set options used during keymap creation
    { '<leader>s', ':SomeCommand<CR>', description = 'Non-silent keymap', opts = { silent = true } },
    -- create keymaps with different implementations per-mode
    {
      '<leader>c',
      { n = ':LinewiseCommentToggle<CR>', x = ":'<,'>BlockwiseCommentToggle<CR>" },
      description = 'Toggle comment',
    },
    -- create item groups to create sub-menus in the finder
    -- note that only keymaps, commands, and functions
    -- can be added to item groups
    {
      -- groups with same itemgroup will be merged
      itemgroup = 'short ID',
      description = 'A submenu of items...',
      icon = '',
      keymaps = {
        -- more keymaps here
      },
    },
    -- in-place filters, see :h legendary-tables or ./doc/table_structures/README.md
    { '<leader>m', description = 'Preview markdown', filters = { ft = 'markdown' } },
  },
  commands = {
    -- easily create user commands
    {
      ':SayHello',
      function()
        print('hello world!')
      end,
      description = 'Say hello as a command',
    },
    {
      -- groups with same itemgroup will be merged
      itemgroup = 'short ID',
      -- don't need to copy the other group data because
      -- it will be merged with the one from the keymaps table
      commands = {
        -- more commands here
      },
    },
    -- in-place filters, see :h legendary-tables or ./doc/table_structures/README.md
    { ':Glow', description = 'Preview markdown', filters = { ft = 'markdown' } },
  },
  funcs = {
    -- Make arbitrary Lua functions that can be executed via the item finder
    {
      function()
        doSomeStuff()
      end,
      description = 'Do some stuff with a Lua function!',
    },
    {
      -- groups with same itemgroup will be merged
      itemgroup = 'short ID',
      -- don't need to copy the other group data because
      -- it will be merged with the one from the keymaps table
      funcs = {
        -- more funcs here
      },
    },
  },
  autocmds = {
    -- Create autocmds and augroups
    { 'BufWritePre', vim.lsp.buf.format, description = 'Format on save' },
    {
      name = 'MyAugroup',
      clear = true,
      -- autocmds here
    },
  },
  -- load extensions
  extensions = {
    -- automatically load keymaps from lazy.nvim's `keys` option
    lazy_nvim = true,
    -- load keymaps and commands from nvim-tree.lua
    nvim_tree = true,
    -- load commands from smart-splits.nvim
    -- and create keymaps, see :h legendary-extensions-smart-splits.nvim
    smart_splits = {
      directions = { 'h', 'j', 'k', 'l' },
      mods = {
        move = '<C>',
        resize = '<M>',
      },
    },
    -- load commands from op.nvim
    op_nvim = true,
    -- load keymaps from diffview.nvim
    diffview = true,
  },
})
```

For more mapping features and more complicated setups see [Table Structures](./doc/table_structures/README.md).

To trigger the finder for your configured keymaps, commands, `augroup`/`autocmd`s, and Lua functions:

Commands:

```VimL
" search keymaps, commands, and autocmds
:Legendary

" search keymaps
:Legendary keymaps

" search commands
:Legendary commands

" search functions
:Legendary functions

" search autocmds
:Legendary autocmds

" repeat the last item executed via legendary.nvim's finder;
" by default, only executes if the last set of item filters used still returns `true`
:LegendaryRepeat

" repeat the last item executed via legendary.nvim's finder, ignoring the filters used
:LegendaryRepeat!
```

Lua API:

The `require('legendary').find()` function takes an `opts` table with the following fields (all optional):

```lua
{
  -- pass a list of filter functions or a single filter function with
  -- the signature `function(item, context): boolean`
  -- (see below for `context` definition)
  -- several filter functions are provided for convenience
  -- see ./doc/FILTERS.md for a list
  filters = {},
  -- pass a function with the signature `function(item, mode): string[]`
  -- returning a list of strings where each string is one column
  -- use this to override the configured formatter for just one call
  formatter = nil,
  -- pass a string, or a function that returns a string
  -- to customize the select prompt for the current call
  select_prompt = nil,
}
```

The `context` table passed to filters contains the following properties:

```lua
{
  buf = number, -- buffer ID
  buftype = string,
  filetype = string,
  mode = string, -- the mode that the UI was triggered from
  cursor_pos = table, -- { row, col }
  marks = table, -- visual mode marks, if applicable; { line, col, line, col }
}
```

See [USAGE_EXAMPLES.md](./doc/USAGE_EXAMPLES.md) for some advanced usage examples.

## Configuration

Default configuration is shown below. For a detailed explanation of the structure for
keymap, command, and `augroup`/`autocmd` tables, see [doc/table_structures/README.md](./doc/table_structures/README.md).

```lua
require('legendary').setup({
  -- Initial keymaps to bind, can also be a function that returns the list
  keymaps = {},
  -- Initial commands to bind, can also be a function that returns the list
  commands = {},
  -- Initial augroups/autocmds to bind, can also be a function that returns the list
  autocmds = {},
  -- Initial functions to bind, can also be a function that returns the list
  funcs = {},
  -- Initial item groups to bind,
  -- note that item groups can also
  -- be under keymaps, commands, autocmds, or funcs;
  -- can also be a function that returns the list
  itemgroups = {},
  -- default opts to merge with the `opts` table
  -- of each individual item
  default_opts = {
    -- for example, { silent = true, remap = false }
    keymaps = {},
    -- for example, { args = '?', bang = true }
    commands = {},
    -- for example, { buf = 0, once = true }
    autocmds = {},
  },
  -- Customize the prompt that appears on your vim.ui.select() handler
  -- Can be a string or a function that returns a string.
  select_prompt = ' legendary.nvim ',
  -- Character to use to separate columns in the UI
  col_separator_char = '│',
  -- Optionally pass a custom formatter function. This function
  -- receives the item as a parameter and the mode that legendary
  -- was triggered from (e.g. `function(item, mode): string[]`)
  -- and must return a table of non-nil string values for display.
  -- It must return the same number of values for each item to work correctly.
  -- The values will be used as column values when formatted.
  -- See function `default_format(item)` in
  -- `lua/legendary/ui/format.lua` to see default implementation.
  default_item_formatter = nil,
  -- Customize icons used by the default item formatter
  icons = {
    -- keymap items list the modes in which the keymap applies
    -- by default, you can show an icon instead by setting this to
    -- a non-nil icon
    keymap = nil,
    command = '',
    fn = '󰡱',
    itemgroup = '',
  },
  -- Include builtins by default, set to false to disable
  include_builtin = true,
  -- Include the commands that legendary.nvim creates itself
  -- in the legend by default, set to false to disable
  include_legendary_cmds = true,
  -- Options for list sorting. Note that fuzzy-finders will still
  -- do their own sorting. For telescope.nvim, you can set it to use
  -- `require('telescope.sorters').fuzzy_with_index_bias({})` when
  -- triggered via `legendary.nvim`. Example config for `dressing.nvim`:
  --
  -- require('dressing').setup({
  --  select = {
  --    get_config = function(opts)
  --      if opts.kind == 'legendary.nvim' then
  --        return {
  --          telescope = {
  --            sorter = require('telescope.sorters').fuzzy_with_index_bias({})
  --          }
  --        }
  --      else
  --        return {}
  --      end
  --    end
  --  }
  -- })
  sort = {
    -- put most recently selected item first, this works
    -- both within global and item group lists
    most_recent_first = true,
    -- sort user-defined items before built-in items
    user_items_first = true,
    -- sort the specified item type before other item types,
    -- value must be one of: 'keymap', 'command', 'autocmd', 'group', nil
    item_type_bias = nil,
    -- settings for frecency sorting.
    -- https://en.wikipedia.org/wiki/Frecency
    -- Set `frecency = false` to disable.
    -- this feature requires sqlite.lua (https://github.com/kkharji/sqlite.lua)
    -- and will be automatically disabled if sqlite is not available.
    -- NOTE: THIS TAKES PRECEDENCE OVER OTHER SORT OPTIONS!
    frecency = {
      -- the directory to store the database in
      db_root = string.format('%s/legendary/', vim.fn.stdpath('data')),
      -- the maximum number of timestamps for a single item
      -- to store in the database
      max_timestamps = 10,
    },
  },
  lazy_nvim = {
    -- Automatically register keymaps that are defined on lazy.nvim plugin specs
    -- using the `keys = {}` property.
    auto_register = false,
  },
  which_key = {
    -- Automatically add which-key tables to legendary
    -- see ./doc/WHICH_KEY.md for more details
    auto_register = false,
    -- you can put which-key.nvim tables here,
    -- or alternatively have them auto-register,
    -- see ./doc/WHICH_KEY.md
    mappings = {},
    opts = {},
    -- controls whether legendary.nvim actually binds they keymaps,
    -- or if you want to let which-key.nvim handle the bindings.
    -- if not passed, true by default
    do_binding = true,
    -- controls whether to use legendary.nvim item groups
    -- matching your which-key.nvim groups; if false, all keymaps
    -- are added at toplevel instead of in a group.
    use_groups = true,
  },
  -- Which extensions to load; no extensions are loaded by default.
  -- Setting the plugin name to `false` disables loading the extension.
  -- Setting it to any other value will attempt to load the extension,
  -- and pass the value as an argument to the extension, which should
  -- be a single function. Extensions are modules under `legendary.extensions.*`
  -- which return a single function, which is responsible for loading and
  -- initializing the extension.
  extensions = {
    nvim_tree = false,
    smart_splits = false,
    op_nvim = false,
    diffview = false,
  },
  scratchpad = {
    -- How to open the scratchpad buffer,
    -- 'current' for current window, 'float'
    -- for floating window
    view = 'float',
    -- How to show the results of evaluated Lua code.
    -- 'print' for `print(result)`, 'float' for a floating window.
    results_view = 'float',
    -- Border style for floating windows related to the scratchpad
    float_border = 'rounded',
    -- Whether to restore scratchpad contents from a cache file
    keep_contents = true,
  },
  -- Directory used for caches
  cache_path = string.format('%s/legendary/', vim.fn.stdpath('cache')),
  -- Log level, one of 'trace', 'debug', 'info', 'warn', 'error', 'fatal'
  log_level = 'info',
})
```

### Troubleshooting Frecency Sort

If you get an error along the lines of the following, and frecency sorting does not work:

```
Failed to open database at /Users/mat/.local/share/nvim/legendary/legendary_frecency.sqlite3: ...at/.local/share/nvim/lazy/sqlite.lua/lua/sqlite/defs.lua:56: dlopen(lib.dylib, 0x0005): tried: 'lib.dylib' (no such file), '/System/Volumes/Preboot/Cryptexes/OSlib.dylib' (no such file), '/nix/store/092zx4zf4fmj0jyk32jl1ihix6q4bmw4-apple-framework-CoreFoundation-11.0.0/Library/Frameworks/lib.dylib' (no such file), '/System/Volumes/Preboot/Cryptexes/OS/nix/store/092zx4zf4fmj0jyk32jl1ihix6q4bmw4-apple-framework-CoreFoundation-11.0.0/Library/Frameworks/lib.dylib' (no such file), '/nix/store/092zx4zf4fmj0jyk32jl1ihix6q4bmw4-apple-framework-CoreFoundation-11.0.0/Library/Frameworks/lib.dylib' (no such file), '/System/Volumes/Preboot/Cryptexes/OS/nix/store/092zx4zf4fmj0jyk32jl1ihix6q4bmw4-apple-framework-CoreFoundation-11.0.0/Library/Frameworks/lib.dylib' (no such file), '/usr/lib/lib.dylib' (no such file, not in dyld cache), 'lib.dylib' (no such file), '/usr/local/lib/lib.dylib' (no such file), '/usr/lib/lib.dylib' (no such file, not in dyld cache)
```

This means that the `sqlite.lua` Lua library was unable to find the `libsqlite3.dylib` shared library file. This could be the case
for a few reasons. To fix this, you can either set `vim.g.sqlite_clib_path` in your Neovim config, or the `LIBSQLITE` environment variable
to the full path to `libsqlite3.dylib`. If you are using Nix with `home-manager`, this can be done like so:

```nix
{
  home.sessionVariables = {
    LIBSQLITE = "${pkgs.sqlite.out}/lib/libsqlite3.dylib";
  };
}
```

If you are _not_ using Nix, you can locate the `libsqlite3.dylib` on macOS by running:

```shell
otool -L $(which sqlite3) | grep "sqlite3.dylib"
```

---

Additional documentation can be found under [doc/](./doc/).
