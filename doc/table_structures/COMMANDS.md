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

You can also pass options to the command via the `opts` property, see `:h nvim_create_user_command` to
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
