# Extensions

<!--toc:start-->

- [Extensions](#extensions)
  - [`nvim-tree.lua`](#nvim-treelua)

<!--toc:end-->

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

## `nvim-tree.lua`

Automatically load keymaps and commands for the `NvimTree` buffer into `legendary.nvim`.

```lua
require('legendary').setup({
  extensions = {
    nvim_tree = true,
  },
})
```
