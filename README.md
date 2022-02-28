# 🗺️ legendary.nvim

<sup>Currently requires Neovim nightly for `vim.keymap.set`, `vim.api.nvim_create_augroup`, and `vim.api.nvim_create_autocmd` APIs</sup>

🗺️ A legend for your keymaps, commands, and autocommands!
Automatically load keymaps from [which-key.nvim](https://github.com/folke/which-key.nvim)!
Think VS Code's Command Palette, but cooler!

<!-- panvimdoc-ignore-start -->

![demo](./demo.gif)
<sup>Theme used in recording is [lighthaus.nvim](https://github.com/mrjones2014/lighthaus.nvim)</sup>

<!-- panvimdoc-ignore-end -->

## Features

- Define your keymaps, commands, and `augroup`/`autocmd`s as simple Lua tables, then bind/create them with `legendary.nvim`
- Uses `vim.ui.select()` so it can be hooked up to a fuzzy finder using something like [dressing.nvim](https://github.com/stevearc/dressing.nvim)
- Search built-in keymaps and commands along with your user-defined keymaps and commands (may be disabled in config). Notice some missing? Comment on [this issue](https://github.com/mrjones2014/legendary.nvim/issues/1) or submit a PR!
- Execute normal and insert mode keymaps, commands, and autocommands, when you select them
- Help execute commands that take arguments by prefilling the command line instead of executing immediately
- Integration with [which-key.nvim](https://github.com/folke/which-key.nvim), use your existing `which-key.nvim` tables with `legendary.nvim`

## Installation

With `packer.nvim`:

```lua
use({'mrjones2014/legendary.nvim'})
```

With `vim-plug`:

```VimL
Plug "mrjones2014/legendary.nvim"
```

## Configuration and Setup

```lua
-- Define your keymaps as a list of tables like so
-- description is required for them to appear when you search
local keymaps = {
  { '<F3>', ':NvimTreeToggle<CR>', description = 'Toggle file tree' },
  -- 'mode' defaults to 'n', but you can specify a different mode
  -- either as a string or a list of multiple modes like `mode = { 'n', 'v' }`
  { '<leader>c', ":'<,'>CommentToggle<CR>", mode = 'v', description = 'Toggle comment' },
  -- you can also pass keymap options via the `opts` table, see `:h vim.keymap.set`
  -- and `:h nvim_set_keymap` for all available options
  -- default opts are `opts = { silent = true }`
  { '<leader>y', ':SomeMappingCommand', opts = { noremap = true, silent = false } },
  -- you can also map lua functions directly as a binding
  -- note that implementations are evaluated immediately
  { '<C-p>', require('legendary').find, description = 'Search key bindings' },
  -- if you need to bind a key to call a function with specific arguments
  -- you can use the `require('legendary').lazy()` helper function
  -- `nil` and `1500` will be passed as the arguments to `formatting_sync` when called
  { '<leader>p', require('legendary').lazy(vim.lsp.buf.formatting_sync, nil, 1500), description = 'Format with 1.5s timeout' },
  -- or, if you need to bind a key to a function from a plugin,
  -- this will call `require('telescope.builtin').oldfiles({ only_cwd = true })` when triggered
  { '<leader>f', require('legendary').lazy_required_fn('telescope.builtin', 'oldfiles', { only_cwd = true }) }
  -- Or add a keybind without a definition (useful for reminding yourself of
  -- keybinds which are set up by plugins, for example, these nvim-cmp mappings)
  { '<C-d>', description = 'Scroll docs up' },
  { '<C-f>', description = 'Scroll docs down' },
}

-- Define your commands with the same table structure
-- Again, description is required for them to appear when you search
local commands = {
  -- You can also use legendar.nvim to create commands!
  { ':DoSomething', ':echo "something"', description = 'Do something!' },
  -- You can also set commands to run a lua function
  { ':DoSomethingWithLua', require('my_module').some_method, description = 'Do something with Lua!' },
  -- You can also define commands without an implementation
  -- this will simply make it appear in vim.ui.select() UI
  -- but will not create the command
  { ':CommentToggle', description = 'Toggle comment' },
  -- You can also have "unfinished" command (commands which need an argument)
  -- by setting `unfinished = true`. You can use `{arg_name}` or `[arg_name]`
  -- at the end of the string as a hint, this will get removed when inserted
  -- to the command line
  { ':MyCommand {some_argument}<CR>', description = 'Command with argument', unfinished = true },
  -- or
  { ':MyCommand [some_argument]<CR>', description = 'Command with argument', unfinished = true },
}

-- Define autocommands with a slightly different table structure
-- the elemensts of the table can be augroups or autocommands,
-- augroups will contain autocommands inside them
local autocommands = {
  -- augroup example
  {
    name = 'LspFormat',
    clear = false, -- default true
    {
      -- event can be a string or table of strings like { 'BufWritePre', 'BufWritePost' }
      'BufWritePre',
      -- definition can be a string or a lua function
      require('my-lsp-utils').format,
      -- description is required for them to appear in finder
      description = 'Format with LSP on save',
      opts = {
        -- autocommand pattern to match, can be a string or table of strings
        -- defaults to '*'
        pattern = '<buffer>',
        once = false,
      }
    }
  },
  -- autocmd example
  {
    -- event can be a string or table of strings like { 'BufWritePre', 'BufWritePost' }
    { 'FileType' },
    -- definition can be a string or a lua function
    ':setlocal conceallevel=0',
    opts = {
      -- autocommand pattern to match, defaults to '*'
      pattern = { 'json', 'jsonc' },
      once = false,
    }
  },
}

-- Then set up legendary.nvim
require('legendary').setup({
  -- Include builtins by default, set to false to disable
  include_builtin = true,
  -- Customize the prompt that appears on your vim.ui.select() handler
  select_prompt = 'Legendary',
  -- Initial keymaps to bind
  keymaps = keymaps,
  -- Initial commands to bind
  commands = commands,
  -- Initial augroups and autocmds to bind
  autocmds = autocommands,
  -- Automatically add which-key tables to legendary
  -- when you call `require('which-key').register()`
  -- for this to work, you must call `require('legendary').setup()`
  -- before any calls to `require('which-key').register()`, and
  -- which-key.nvim must be loaded when you call `require('legendary').setup()`
  auto_register_which_key = true,
})

-- Add an additional set of keybinds
-- (useful for binding LSP keybinds in the `on_attach` function, for example)
require('legendary').bind_keymaps({
  { 'gd', vim.lsp.buf.definition, description = 'Go to definition' },
  { 'gh', vim.lsp.buf.hover, description = 'Show hover information' },
  { 'gi', vim.lsp.buf.implementation, description = 'Go to implementation' },
})

require('legendary').bind_commands({
  { ':Format', vim.lsp.buf.formatting_sync, description = 'Format the document with LSP' },
})

-- Or, you can dynamically bind a single keybind or command
require('legendary').bind_keymap({ '<leader>nh', ':noh<CR>', description = 'Remove hlsearch highlighting' })
require('legendary').bind_command({ ':Format', vim.lsp.buf.formatting_sync, description = 'Format the document with LSP' })

-- Dynamically bind a single augroup, a list of augroups,
-- a single autocmd, or a list of autocmds
require('legendary').bind_au(autocommands)
require('legendary').bind_au({
  'BufWritePre',
  ':Format',
  description = 'Format with LSP on save',
  opts = {
    -- autocommand pattern to match, defaults to '*'
    pattern = '<buffer>',
    once = false,
  }
})
require('legendary').bind_au({
  { 'VimEnter', ':SomeCommand' },
  {
    'BufEnter',
    ':set conceallevel=0',
    opts = {
      pattern = {
      '*.json',
      '*.jsonc'
      }
    }
  }
})
```

### [which-key.nvim](https://github.com/folke/which-key.nvim) Integration

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

## Usage

By default, keymaps and commands will be searched together, but you can also search one or the other.

### With Lua:

```lua
require('legendary').find() -- search keymaps, commands, and autocmds
require('legendary').find('keymaps') -- search keymaps
require('legendary').find('commands') -- search commands
require('legendary').find('autocmds') -- search autocmds
```

### With Commands:

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

### Sorting

`legendary.nvim` will set `kind` to `legendary-keymaps`, `legendary-commands`, `legendary-autocmds`,
or `legendary-items`, depending on whether you are searching keymaps, commands, autocmds, or all.

You can use to override the sorter used for `legendary.nvim` in your `vim.ui.select()`
handler (for example, [dressing.nvim](https://github.com/stevearc/dressing.nvim) has a
`get_config` option to do this).

The individual items will have `kind = 'legendary-keymap'`, `kind = 'legendary-command`,
or `kind = 'legendary-autocmd`, depending on whether it is a keymap, command, or autocmd.

## Developing Keymaps, Commands, etc.

`legendary.nvim` also provides some utilities for developing Lua keymaps, commands, etc.
The following commands are available once `legendary.nvim` is loaded:

- `:LegendaryScratch` - create a scratchpad buffer to test Lua snippets in
- `:LegendaryEvalLine` - evaluate the current line as a Lua expression
- `:LegendaryEvalLines` - evaluate the line range selected in visual mode as a Lua snippet
- `:LegendaryEvalBuf` - evaluate the entire current buffer as a Lua snippet

Any `return` value from evaluated Lua is printed to the command area.
