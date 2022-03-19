# Legendary

Define your keymaps, commands, and autocommands as simple Lua tables, building a legend at the same time.

<!-- panvimdoc-ignore-start -->

![demo](https://user.fm/files/v2-076f25de98ac622aaa39c093aa22a11b/legendary-demo.gif)
<sup>Theme used in recording is [lighthaus.nvim](https://github.com/mrjones2014/lighthaus.nvim). The finder UI is handled by [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) via [dressing.nvim](https://github.com/stevearc/dressing.nvim). See [Prerequisites](#prerequisites) for details.</sup>

<!-- panvimdoc-ignore-end -->

## Features

- Define your keymaps, commands, and `augroup`/`autocmd`s as simple Lua tables, then bind them with `legendary.nvim`
- Integration with [which-key.nvim](https://github.com/folke/which-key.nvim), use your existing `which-key.nvim` tables with `legendary.nvim`
- Uses `vim.ui.select()` so it can be hooked up to a fuzzy finder using something like [dressing.nvim](https://github.com/stevearc/dressing.nvim) for a VS Code command palette like interface
- Execute normal, insert, and visual mode keymaps, commands, and autocommands, when you select them
- Show your most recently executed keymap, command, or autocmd at the top when triggered via `legendary.nvim` (can be disabled via config)
- Buffer-local keymaps, commands, and autocmds only appear in the finder for the current buffer
- Help execute commands that take arguments by prefilling the command line instead of executing immediately
- Search built-in keymaps and commands along with your user-defined keymaps and commands (may be disabled in config). Notice some missing? Comment on [this issue](https://github.com/mrjones2014/legendary.nvim/issues/1) or submit a PR!

## Prerequisites

- Neovim nightly (0.7+); specifically, this plugin depends on the following APIs:
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
require('legendary').find() -- search keymaps, commands, and autocmds
require('legendary').find('keymaps') -- search keymaps
require('legendary').find('commands') -- search commands
require('legendary').find('autocmds') -- search autocmds
```

Vim commands:

```VimL
:Legendary " search keymaps, commands, and autocmds
:Legendary keymaps " search keymaps
:Legendary commands " search commands
:Legendary autocmds " search autocmds
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
  -- Automatically add which-key tables to legendary
  -- see "which-key.nvim Integration" below for more details
  auto_register_which_key = true,
})
```

### `which-key.nvim` Integration

Already a `which-key.nvim` user? Use your existing `which-key.nvim` tables with `legendary.nvim`!

```lua
-- automatically register which-key.nvim tables with legendary.nvim
-- when you register them with which-key.nvim.
-- `setup()` must be called before `require('which-key).register()`
require('legendary').setup()
-- now this will register them with both which-key.nvim and legendary.nvim
require('which-key').register(your_which_key_tables, your_which_key_opts)

-- alternatively, if you'd prefer to manually register with legendary.nvim
require('legendary').setup({ auto_register_which_key = false })
require('which-key').register(your_which_key_tables, your_which_key_opts)
require('legendary').bind_whichkey(your_which_key_tables, your_which_key_opts)
```

## Table Structures

The tables for keymaps, commands, and `augroup`/`autocmd`s are all similar.

For `autocmd`s, you must include a `description` property for it to appear in the finder.
This is a design decision because keymaps and commands are frequently executed manually,
so they should appear in the finder by default, while executing `autocmd`s manually with
`:doautocmd` is a much less common use-case, so `autocmd`s are hidden from the finder
unless a description is provided.

<details>
<summary>Keymaps</summary>

For keymaps you are mapping yourself (as opposed to mappings set by other plugins),
the first two elements are the key and the handler, respectively. The handler
can be a command string like `:wa<CR>` or a Lua function. Example:

```lua
local keymaps = {
  { '<leader>s', ':wa<CR>', description = 'Write all buffers', opts = {} },
  { '<leader>fm', vim.lsp.buf.formatting_sync, description = 'Format buffer with LSP' },
}
```

If you need to pass parameters to the Lua function or call a function dynamically from a plugin,
you can use the following helper functions:

```lua
local helpers = require('legendary.helpers')
local keymaps = {
  { '<leader>p', helpers.lazy(vim.lsp.buf.formatting_sync, nil, 1500), description = 'Format with 1.5s timeout' },
  { '<leader>f', helpers.lazy_required_fn('telescope.builtin', 'oldfiles', { only_cwd = true }) }
}
```

The keymap's mode defaults to normal (`n`), but you can set a different mode, or list of modes, via
the `mode` property:

```lua
local keymaps = {
  { '<leader>c', ':CommentToggle<CR>', description = 'Toggle comment', mode = { 'n', 'v' } }
}
```

You can also pass options to the keymap via the `opts` property, see `:h vim.keymap.set` to
see available options.

```lua
local keymaps = {
  {
    '<leader>fm',
    vim.lsp.buf.formatting_sync,
    description = 'Format buffer with LSP',
    opts = { silent = true, noremap = true }
  },
}
```

If you want a keymap to apply to both normal and insert mode, use a Lua function.
The function will be given a table containing the visual selection range (the marks
will also be set). This allows you to create mappings like:

```lua
local keymaps = {
  {
    '<leader>c',
    function(visual_selection)
      if visual_selection then
        -- comment a visual block
        vim.cmd(":'<,'>CommentToggle")
      else
        -- comment a single line from normal mode
        vim.cmd(':CommentToggle')
      end
    end,
    description = 'Toggle comment',
    mode = { 'n', 'v' },
  }
}
```

Finally, if you want to register keymaps with `legendary.nvim` in order to see them in the finder, but not bind
them (like for keymaps set by other plugins), you can just omit the handler element:

```lua
local keymaps = {
  { '<C-d>', description = 'Scroll docs up' },
  { '<C-f>', description = 'Scroll docs down' },
}
```

</details>

<details>
<summary>Commands</summary>

Command tables follow the exact same structure as keymaps, but specify a command name instead of a key code.

```lua
local commands = {
  { ':DoSomething', ':echo "something"', description = 'Do something!' },
  { ':DoSomethingWithLua', require('some-module').some_method, description = 'Do something with Lua!' },
  -- a command from a plugin, don't specify a handler
  { ':CommentToggle', description = 'Toggle comment' },
}
```

You can also pass options to the command via the `opts` property, see `:h nvim_add_user_command` to
see available options. In addition to those options, `legendary.nvim` adds handling for an additional
`buffer` option (a buffer handle, or `0` for current buffer), which will cause the command to be bound
as a buffer-local command.

If you need a command to take an argument, specify `unfinished = true` to pre-fill the command line instead
of executing the command on selected. You can put an argument name/hint in `[]` or `{}` that will be stripped
when filling the command line.

```lua
local commands = {
  { ':MyCommand {some_argument}<CR>', description = 'Command with argument', unfinished = true },
  -- or
  { ':MyCommand [some_argument]<CR>', description = 'Command with argument', unfinished = true },
}
```

</details>

<details>
<summary><code>augroup</code>s and <code>autocmd</code>s</summary>

`augroup` tables are very simple. They have a `name` property, and a `clear` property which defaults to `true`.
This will clear the `augroup` when creating it, equivalent to `au!`. `autocmd` tables nested within `augroup`
tables will automatically be defined in the `augroup`.

```lua
local augroups = {
  {
    name = 'MyAugroupName',
    clear = true,
    -- you autocmd tables here
  }
}
```

`autocmd` tables have an event or list of events, and a handler as the first two elements, respectively.
You can also specify options to be passed to the `autocmd` via the `opts` property. The `opts` property
defaults to `{ pattern = '*', group = nil }`.

```lua
local autocmds = {
  {
    'FileType',
    ':setlocal conceallevel=0',
    opts = {
      pattern = { 'json', 'jsonc' },
    },
  },
  {
    { 'BufRead', 'BufNewFile' },
    ':set filetype=jsonc',
    opts = {
      pattern = { '*.jsonc', 'tsconfig*.json' },
    },
  },
  {
    'BufWritePre',
    vim.lsp.buf.formatting_sync,
    -- include a description to execute it
    -- like a command on-demand from the finder
    description = 'Format on write with LSP',
  },
}
```

An example putting both together:

```lua
local augroups = {
  {
    name = 'LspOnAttachAutocmds',
    clear = true,
    {
      'BufWritePre',
      require('lsp.utils').format_document,
    },
    {
      'CursorHold',
      vim.diagnostic.open_float,
    },
  },
  {
    { 'BufRead', 'BufNewFile' },
    ':set filetype=jsonc',
    opts = {
      -- you can also manually add an autocmd
      -- to an existing augroup
      group = 'filetypedetect',
      pattern = { '*.jsonc', 'tsconfig*.json' },
    },
  }
}
```

</details>

## Lua API

You can also manually bind new items after you've already called `require('legendary').setup()`.
This can be useful for things like binding language-specific keyaps in the LSP `on_attach` function.

The following API functions are available:

```lua
-- bind a single keymap
require('legendary').bind_keymap(keymap)
-- bind a list of keymaps
require('legendary').bind_keymaps({
  -- your keymaps here
})

-- bind a single command
require('legendary').bind_command(command)
-- bind a list of commands
require('legendary').bind_commands({
  -- your commands here
})

-- bind single or multiple augroups and/or autocmds
-- these all use the same function
require('legendary').bind_autocmds(augroup)
require('legendary').bind_autocmds(autocmd)
require('legendary').bind_autocmds({
  -- your augroups and autocmds here
})
```

### Item Kinds

`legendary.nvim` will set the `kind` option on `vim.ui.select()` to `legendary.keymaps`,
`legendary.commands`, `legendary.autocmds`, or `legendary-items`, depending on whether you
are searching keymaps, commands, autocmds, or all.

The individual items will have `kind = 'legendary.keymap'`, `kind = 'legendary.command'`,
or `kind = 'legendary.autocmd'`, depending on whether it is a keymap, command, or autocmd.

Builtins will have `kind = 'legendary.keymap.bulitin'`, `kind = 'legendary.command.builtin'`,
or `kind = 'legendary.autocmd'`, depending on whether it is a built-in keymap, command, or autocmd.

### Lua Helpers for Creating Mappings, Commands, and Autocmds

When creating keymaps to Lua functions, the Lua expressions are evaluated at the time the mappings
table is first read by nvim. This means you typically need to pass a function _reference_ instead
of calling the function. For example, you probably want to map `vim.lsp.buf.formatting_sync`, _not_
`vim.lsp.buf.formatting_sync()`.

If you need to pass arguments to a function when it's called, you can use the `lazy` helper:

```lua
-- lazy() takes the first argument (a function)
-- and calls it with the rest of the arguments
require('legendary.helpers').lazy(vim.lsp.buf.formatting_sync, nil, 1500)
-- this will *return a new function* defined as:
function()
  vim.lsp.buf.formatting_sync(nil, 1500)
end
```

If you need to call a function from Legendary, but the plugin won't be loaded at the time
you define your keymaps (for example, if you're using Packer to lazy-load plugins), you can use the
`lazy_required_fn` helper:

```lua
-- lazy_required_fn() takes a module path as the first argument,
-- a function name from that module as the second argument,
-- and returns a new function that calls the function by name
-- with the rest of the arguments
require('legendary.helpers').lazy_required_fn('telescope.builtin', 'oldfiles', { only_cwd = true })
-- this will *return a new function* defined as:
function()
  require('telescope.bulitin')['oldfiles']({ only_cwd = true })
end
```

If you want to create a keymap that creates a split pane, then does something in the new pane,
there are helpers for that too:

```lua
-- split_then() and vsplit_then() both take a Lua function as the
-- only parameter, and return a new function that creates a
-- horizontal or vertical split, then calls the specified Lua function
require('legendary.helpers').split_then(vim.lsp.buf.definition)
-- this will *return a new function* defined as:
function()
  vim.cmd('sp')
  vim.lsp.buf.definition()
end

-- and likewise, this:
require('legendary.helpers').vsplit_then(vim.lsp.buf.definition)
-- will *return a new function* defined as:
function()
  vim.cmd('vsp')
  vim.lsp.buf.definition()
end
```

These helpers can also be composed together. For example, to create a function that creates a vertical
split, then uses Telescope to find and open a file in the new split, you could write:

```lua
local helpers = require('legendary.helpers')
helpers.vsplit_then(helpers.lazy_required_fn('telescope', 'find_file', { only_cwd = true }))
```

## Utilities

`legendary.nvim` also provides some utilities for developing Lua keymaps, commands, etc.
The following commands are available once `legendary.nvim` is loaded:

- `:LegendaryScratch` - create a scratchpad buffer to test Lua snippets in
- `:LegendaryEvalLine` - evaluate the current line as a Lua expression
- `:LegendaryEvalLines` - evaluate the line range selected in visual mode as a Lua snippet
- `:LegendaryEvalBuf` - evaluate the entire current buffer as a Lua snippet

Any `return` value from evaluated Lua is printed to the command area.

## Sponsors

Huge thanks to my sponsors for helping to support this project:

- [@olimorris](https://github.com/olimorris)
