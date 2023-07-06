# Functions

## Basic functions

Functions follow a similar structure as anonymous [commands](./COMMANDS.md), but description is **required**.

```lua
local functions = {
  {
    function()
      vim.lsp.buf.code_action({
        filter = function(a)
          return a.isPreferred
        end,
        apply = true,
      })
    end,
    description = 'Auto Fix...',
  },
  {
    function()
      if require('legendary.toolbox').is_visual_mode() then
        local cline, _, vline, _ = unpack(require('legendary.toolbox').get_marks())
        require('gitsigns').reset_hunk({ cline, vline })
      else
        require('gitsigns').reset_hunk()
      end
    end,
    description = 'Revert Selected Ranges/Reset the lines of the hunk',
  },
  { lazy(vim.cmd.Telescope, 'git_files'), description = 'Git Files' },
}
```

## Options

You can also pass options via the `opts` property:

- `buffer` option (a buffer handle, or `0` for current buffer), which will
  make the function visible only in the specified buffer.

## Item Groups

You can also organize keymaps, commands, and functions into groups that will show up
in the finder UI like a folder, selecting it will then trigger another finder for items
within the group. If groups are given the same name, they will be merged.

```lua
local functions = {
  {
    -- name, indicates that this table is an item group
    itemgroup = 'short ID',
    -- you can also customize the icon for item groups
    icon = '',
    -- you can also customize the description (first text column)
    description = 'A group of items, this can be a little longer...',
    funcs = {
      -- regular legendary.nvim functions here
    },
  },
}
```
