# bindr.nvim
<sup>Currently requires Neovim nightly for `vim.keymap.set` API</sup>

Define your keymaps as Lua tables, add descriptions, and find them with `vim.ui.select()` when you forget.

For normal and insert mode mappings, you can execute the mapping by selecting it. You can use something
like [dressing.nvim](https://github.com/stevearc/dressing.nvim) to use a fuzzy finder as your default
`vim.ui.*` handler.

```lua
-- Define your keymaps as a list of tables like so
-- description is required for them to appear when you search
local keymaps = {
  { '<F3>', ':NvimTreeToggle<CR>', description = 'Toggle file tree' },
  -- 'mode' defaults to 'n', but you can specify a differet mode
  -- either as a string or a list of multiple modes like `mode = { 'n', 'v' }`
  { '<leader>c', ":'<,'>CommentToggle<CR>", mode = 'v', description = 'Toggle comment' },
  { '<leader>m', ':messages<CR>' },
  -- you can also map lua functions directly as a binding
  { '<C-p>', require('bindr').find, description = 'Search key bindings' }
}

-- Then install the plugin (using packer.nvim in this example)
require('packer').startup(function(use)
  -- your other plugins here
  use({
    'mrjones2014/bindr.nvim',
    config = function()
      -- Then bind your keymaps and register them in the finder
      require('bindr').bind(keymaps)
      -- Or, you can dynamically bind a single keybind
      require('bindr').bind({ '<leader>nh', ':noh<CR>', description = 'Remove hlsearch highlighting' })
    end
  }),
end)


-- Then find them with `vim.ui.select()` via
require('bindr').find()
```
