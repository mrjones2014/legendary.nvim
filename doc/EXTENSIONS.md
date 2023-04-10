# Extensions

<!--toc:start-->

- [Extensions](#extensions)
  - [Extension API](#extension-api)
  - [Built-in Extensions](#built-in-extensions)
    - [`nvim-tree.lua`](#nvim-treelua)
    - [`smart-splits.nvim`](#smart-splitsnvim)
    - [`op.nvim`](#opnvim)
    - [`diffview.nvim`](#diffviewnvim)

<!--toc:end-->

> **Note**
> The internal extension API is considered unstable, as it will likely need to evolve as we add
> extensions for additional plugins with different setups. This mostly affects plugin developers,
> not users.

`legendary.nvim` extensions can automatically load keymaps and commands from other plugins with
very little configuration.

To enable a plugin, specify it in your `legendary.nvim` config, under `extensions`, where the key
is the extension name and the value is the extension config (or `false` to disable an extension).

```lua
require('legendary').setup({
  extensions = {
    -- nvim-tree.lua extension takes no config,
    -- just use `true`
    nvim_tree = true,
    -- this table will be passed as extension config
    some_extension = {
      some_extension_config = some_value,
    },
  },
})
```

## Extension API

To create a new extension, create a Lua module under the `legendary.extensions.*` namespace; for example, to create an
extension called `my_extension`, create a Lua module `legendary.extensions.my_extension`. The module should return a
single function, which may take a single argument which can be used as configuration. The configuration can be any value
you need, such as a table of configuration, as it will be passed via the user's config.

The function returned from an extension is responsible for initializing and setting up anything the extension needs.
You should do as little work as possible up front, as extensions are loaded on startup. Sometimes, you can use
autocmds provided by the plugin you're writing an extension for (see
[legendary.extensions.nvim_tree.lua](../lua/legendary/extensions/nvim_tree.lua)), or alternatively, you may use
the `require('legendary.extensions').pre_ui_hook(callback)` utility function. This sets up `callback` to be called
immediately before the `legendary.nvim` UI is launched, and when the function returns `true`, it will remove itself.
You can use this to try to load keymaps/commands/etc. right before the UI is launched, but if you successfully load
them, you should `return true` so they don't get loaded multiple times.

If you need more fine-grained control over this, you can use the `User LegendaryUiPre` autocmd pattern directly, which
is how `require('legendary.extensions').pre_ui_hook(callback)` works internally.

Loading keymaps/commands/etc. from an extension can use the same APIs a user would use to do so, e.g.
`require('legendary').keymaps(my_keymaps)`.

## Built-in Extensions

### `nvim-tree.lua`

Automatically load keymaps and commands for the `NvimTree` buffer into `legendary.nvim`.

```lua
require('legendary').setup({
  extensions = {
    nvim_tree = true,
  },
})
```

### `smart-splits.nvim`

Automatically load commands from `smart-splits.nvim`. This extension can also create the keymaps for you automatically
by passing an `opts` table to the extension.

```lua
require('legendary').setup({
  extensions = {
    smart_splits = true, -- do not create keymaps
    -- or, default settings shown below
    smart_splits = {
      directions = { 'h', 'j', 'k', 'l' },
      mods = {
        -- for moving cursor between windows
        move = '<C>',
        -- for resizing windows
        resize = '<M>',
        -- for swapping window buffers
        swap = false, -- false disables creating a binding
      },
    },
    -- or, customize
    smart_splits = {
      directions = { 'h', 'j', 'k', 'l' },
      mods = {
        move = '<C>',
        resize = '<M>',
        -- any of these can also be a table of the following form
        swap = {
          -- this will create the mapping like
          -- <leader><C-h>
          -- <leader><C-j>
          -- <leader><C-k>
          -- <leader><C-l>
          mod = '<C>',
          prefix = '<leader>',
        },
      },
    },
  },
})
```

### `op.nvim`

Automatically load commands from `op.nvim`.

```lua
require('legendary').setup({
  extensions = {
    op_nvim = true,
  },
})
```

### `diffview.nvim`

Automatically load commands and keymaps from `diffview.nvim`. The keymaps will only appear in the `legendary.nvim`
UI for the currently active `diffview.nvim` view to which they apply.

```lua
require('legendary').setup({
  extensions = {
    diffview = true,
  },
})
```
