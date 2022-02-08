# legendary.nvim 🗺️

<sup>Currently requires Neovim nightly for `vim.keymap.set` API</sup>

A legend for your keymaps and commands 🗺️

![demo](./demo.gif)

Define your keymaps as simple Lua tables and let `legendary.nvim` handle the rest.
Find them (and commands) with `vim.ui.select()` when you forget.

It also includes built-in keymaps and commands (these can be removed via config). Please help
me add missing ones with a Pull Request!

For normal and insert mode mappings, you can execute the mapping by selecting it. You can use something
like [dressing.nvim](https://github.com/stevearc/dressing.nvim) to use a fuzzy finder as your default
`vim.ui.*` handler. Since it uses `vim.ui.select()`, it can pretty much support any fuzzy finder.

## Installation

With `packer.nvim`:

```lua
use('mrjones2014/legendary.nvim')
```

With `vim-plug`:

```VimL
Plug 'mrjones2014/legendary.nvim'
```

## Configuration

```lua
-- Define your keymaps as a list of tables like so
-- description is required for them to appear when you search
local keymaps = {
  { '<F3>', ':NvimTreeToggle<CR>', description = 'Toggle file tree' },
  -- 'mode' defaults to 'n', but you can specify a different mode
  -- either as a string or a list of multiple modes like `mode = { 'n', 'v' }`
  { '<leader>c', ":'<,'>CommentToggle<CR>", mode = 'v', description = 'Toggle comment' },
  { '<leader>m', ':messages<CR>' },
  -- you can also pass keymap options via the `opts` table, see `:h vim.keymap.set`
  -- and `:h nvim_set_keymap` for all available options
  -- default opts are `opts = { silent = true }`
  { '<leader>f', ':SomeMappingCommand', opts = { noremap = true, silent = false } },
  -- you can also map lua functions directly as a binding
  { '<C-p>', require('legendary').find, description = 'Search key bindings' },
  -- You can also have items that aren't bound to any key, but are executable
  -- through the finder by omitting a keycode, this way you can use
  -- legendary.nvim like VS Code's Command Palette
  { ':CommentToggle<CR>', description = 'Toggle comment' },
  -- Or add a keybind without a definition (useful for reminding yourself of
  -- keybinds which are set up by plugins, for example, these nvim-cmp mappings)
  { '<C-d>', description = 'Scroll docs up' },
  { '<C-f>', description = 'Scroll docs down' },
  -- You can also have "unfinished" command (commands which need an argument)
  -- by setting `unfinished = true`. You can use `{arg_name}` or `[arg_name]`
  -- at the end of the string as a hint, this will get removed when inserted
  -- to the command line
  { ':MyCommand {some_argument}<CR>', description = 'Command with argument', unfinished = true },
  -- or
  { ':MyCommand [some_argument]<CR>', description = 'Command with argument', unfinished = true },
}

-- Then set up legendary.nvim
require('legendary').setup({
  -- Include builtins by default, set to false to disable
  include_builtin = true,
  -- Customize the prompt that appears on your vim.ui.select() handler
  select_prompt = 'Legendary',
  keymaps = {}
})

-- Add an additional set of keybinds
-- (useful for binding LSP keybinds in the `on_attach` function, for example)
require('legendary').bind({
  { 'gd', vim.lsp.buf.definition, description = 'Go to definition' },
  { 'gh', vim.lsp.buf.hover, description = 'Show hover information' },
  { 'gi', vim.lsp.buf.implementation, description = 'Go to implementation' },
})

-- Or, you can dynamically bind a single keybind
require('legendary').bind({ '<leader>nh', ':noh<CR>', description = 'Remove hlsearch highlighting' })
```

## Usage

Trigger the legend with `require('legendary').find()`, `:Legend`, or `:Legendary`.
