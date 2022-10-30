# Legendary.nvim

Define your keymaps, commands, and autocommands as simple Lua tables, building a legend at the same time.

<!-- panvimdoc-ignore-start -->

![demo](https://user-images.githubusercontent.com/8648891/160112850-5fbbf327-309c-4bac-ad6b-df217127d886.gif)
<sup>Theme used in recording is [lighthaus.nvim](https://github.com/mrjones2014/lighthaus.nvim). The finder UI is handled by [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) via [dressing.nvim](https://github.com/stevearc/dressing.nvim). See [Prerequisites](#prerequisites) for details.</sup>

<details>
<summary>Table of Contents (click to expand)</summary>

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Item Kinds](#item-kinds)
- [Keymap Development Utilities](./doc/MAPPING_DEVELOPMENT.md)
- [`which-key.nvim` Integration](./doc/WHICH_KEY.md)
- [Lua API](./doc/API.md)
- [Table Structures](./doc/table_structures/README.md)
  - [Keymaps](./doc/table_structures/KEYMAPS.md)
  - [Commands](./doc/table_structures/COMMANDS.md)
  - [Functions](./doc/table_structures/FUNCTIONS.md)
  - [`augroup`/`autocmd`s](./doc/table_structures/AUTOCMDS.md)

</details>

<!-- panvimdoc-ignore-end -->

## Features

- Define your keymaps, commands, and `augroup`/`autocmd`s as simple Lua tables, then bind them with `legendary.nvim`
- Integration with [which-key.nvim](https://github.com/folke/which-key.nvim), use your existing `which-key.nvim` tables with `legendary.nvim`
- Anonymous mappings -- show mappings/commands in the finder without having `legendary.nvim` handle creating them
- Uses `vim.ui.select()` so it can be hooked up to a fuzzy finder using something like [dressing.nvim](https://github.com/stevearc/dressing.nvim) for a VS Code command palette like interface
- Execute normal, insert, and visual mode keymaps, commands, and autocommands, when you select them
- Show your most recently executed keymap, command, function or autocmd at the top when triggered via `legendary.nvim` (can be disabled via config)
- Buffer-local keymaps, commands, functions and autocmds only appear in the finder for the current buffer
- Help execute commands that take arguments by prefilling the command line instead of executing immediately
- Search built-in keymaps and commands along with your user-defined keymaps and commands (may be disabled in config). Notice some missing? Comment on [this discussion](https://github.com/mrjones2014/legendary.nvim/discussions/89) or submit a PR!
- A `legendary.helpers` module to help create lazily-evaluated keymaps and commands. Have an idea for a new helper? Comment on [this discussion](https://github.com/mrjones2014/legendary.nvim/discussions/90) or submit a PR!

## Prerequisites

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
```

Lua API:

The `require('legend').find()` function takes an `opts` table with the following fields (all optional):

```lua
{
  -- pass 'keymaps', 'commands', or 'autocmds' to search only one type of item
  kind = nil,
  -- pass a list of filter functions or a single filter function with
  -- the signature `function(item): boolean`
  -- `require('legendary.filters').mode(mode)` and `require('legendary.filters').current_mode()`
  -- are provided for convenience
  filters = {},
  -- pass a function with the signature `function(item, mode): {string}`
  -- returning a list of strings where each string is one column
  -- use this to override the configured formatter for just one call
  formatter = nil,
  -- pass a string, or a function with the signature `function(kind: string): string`
  -- to customize the select prompt for the current call
  select_prompt = nil,
}
```

See [USAGE_EXAMPLES.md](./doc/USAGE_EXAMPLES.md) for some advanced usage examples.

## Configuration

Default configuration is shown below. For a detailed explanation of the structure for
keymap, command, and `augroup`/`autocmd` tables, see [doc/table_structures/README.md](./doc/table_structures/README.md).

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
  -- receives the item as a parameter and the mode that legendary
  -- was triggered from (e.g. `function(item, mode): {string}`)
  -- and must return a table of non-nil string values for display.
  -- It must return the same number of values for each item to work correctly.
  -- The values will be used as column values when formatted.
  -- See function `get_default_format_values(item)` in
  -- `lua/legendary/formatter.lua` to see default implementation.
  formatter = nil,
  col_separator_char = '│',
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
  -- Initial functions to bind
  functions = {
    -- your function tables here
  },
  -- Initial augroups and autocmds to bind
  autocmds = {
    -- your autocmd tables here
  },
  which_key = {
    -- you can put which-key.nvim tables here,
    -- or alternatively have them auto-register,
    -- see ./doc/WHICH_KEY.md
    mappings = {},
    opts = {},
    -- controls whether legendary.nvim actually binds they keymaps,
    -- or if you want to let which-key.nvim handle the bindings.
    -- if not passed, true by default
    do_binding = {},
  },
  -- Automatically add which-key tables to legendary
  -- see ./doc/WHICH_KEY.md for more details
  auto_register_which_key = false,
  -- settings for the :LegendaryScratch command
  scratchpad = {
    -- configure how to show results of evaluated Lua code,
    -- either 'print' or 'float'
    -- Pressing q or <ESC> will close the float
    display_results = 'float',
    -- cache the contents of the scratchpad to a file and restore it
    -- next time you open the scratchpad
    cache_file = string.format('%s/%s', vim.fn.stdpath('cache'), 'legendary_scratch.lua'),
  },
})
```

## Item Kinds

`legendary.nvim` will set the `kind` option on `vim.ui.select()` to `legendary.keymaps`,
`legendary.commands`, `legendary.functions`, `legendary.autocmds`, or `legendary.items`, depending on whether you
are searching keymaps, commands, functions, autocmds, or all.

The individual items will have `kind = 'legendary.keymap'`, `kind = 'legendary.command'`,
or `kind = 'legendary.function'`, `kind = 'legendary.autocmd'`, depending on whether it is a keymap, command, or autocmd.

Builtins will have `kind = 'legendary.keymap.builtin'`, `kind = 'legendary.command.builtin'`,
`kind = 'legendary.function'`, or `kind = 'legendary.autocmd'`, depending on whether it is a built-in keymap, command, function, or autocmd.
