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

## Specifying mode

By default, the funciton is shown and run in `*` (all) modes.
You can use `mode` property to narrow function's scope, so it always run in specified mode:

```lua
local functions = {
  {
    mode = 'x', description = 'My function',
    function() print('only runs in charwise-visual and selection mode!') end
  },
  {
    description = 'Buffer: git: stage selected hunk'
    mode = { 'x', 'V', 'v' },
    function()
      gitsigns.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') })
    end
  }
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
