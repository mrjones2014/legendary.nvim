# Commands

Command tables follow the exact same structure as [keymaps](./KEYMAPS.md), but specify
a command name instead of a key sequence.

```lua
local commands = {
  { ':DoSomething', ':echo "something"', description = 'Do something!' },
  { ':DoSomethingWithLua', require('some-module').some_method, description = 'Do something with Lua!' },
  -- a command from a plugin, don't specify a handler
  { ':CommentToggle', description = 'Toggle comment' },
}
```

You can also create per-mode implementations, like per-mode keymappings, but since they are all bound
to the same command, per-mode implementations for commands may only be a `function` or a `string` (not a `table`),
since they cannot have separate `opts`.

```lua
local commands = {
  {
    -- example command for toggling comment with Comment.nvim
    ':Comment',
    {
      n = 'gcc',
      v = 'gc',
    },
    description = 'Toggle comment',
  },
  {
    ':DoSomething',
    {
      n = ':SomethingElse<CR>',
      v = function()
        print('Do something else in visual mode')
      end,
      c = function()
        print('Do another thing in command mode')
      end,
    },
    description = 'Do stuff per-mode',
  },
}
```

You can also pass options to the command via the `opts` property, see `:h nvim_create_user_command` to
see available options. In addition to those options, `legendary.nvim` adds handling for an additional
`buffer` option (a buffer handle, or `0` for current buffer), which will cause the command to be bound
as a buffer-local command.

For "anonymous" commands (commands you want to appear in the finder but don't need `legendary.nvim` to
handle creating), just omit the second entry (the "implementation"):

```lua
local commands = {
  {
    ':LspRestart',
    description = 'Restart any attached LSP clients',
  },
}
```

If you need a command to take an argument, specify `unfinished = true` to pre-fill the command line instead
of executing the command on selected. You can put an argument name/hint in `[]` or `{}` that will be stripped
when filling the command line.

```lua
local commands = {
  { ':MyCommand {some_argument}<CR>', description = 'Command with argument', unfinished = true },
  -- or
  { ':MyCommand [some_argument]<CR>', description = 'Command with argument', unfinished = true },
  -- and, with an implementation
  {
    ':MyCommand [some_argument]<CR>',
    function(input)
      -- see :h nvim_create_user_command
      if input.fargs and input.fargs[1] and input.fargs[1] == 'some expected value' then
        -- do something with input.fargs[1]
      end
    end,
    description = 'Command with argument handling',
    unfinished = true,
  },
}
```

You can also organize keymaps, commands, and functions into groups that will show up
in the finder UI like a folder, selecting it will then trigger another finder for items
within the group. If groups are given the same name, they will be merged.

```lua
local commands = {
  {
    -- name, indicates that this table is an item group
    itemgroup = 'Group of items...',
    commands = {
      -- regular commands here
    },
  },
}
```
