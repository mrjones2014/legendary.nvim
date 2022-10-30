# Mapping Development Utilities

`legendary.nvim` also provides some utilities to help with
mapping/command/autocmd development.

## Utility Commands

- `:LegendaryScratch` - create a scratchpad buffer to test Lua snippets in
- `:LegendaryEvalLine` - evaluate the current line as a Lua expression
- `:LegendaryEvalLines` - evaluate the line range selected in visual mode as a Lua snippet
- `:LegendaryEvalBuf` - evaluate the entire current buffer as a Lua snippet
- `:LegendaryApi` - view full Lua API docs for `legendary.nvim`

Any `return` value from evaluated Lua is displayed by your configured method (either `print`ed
to the command area, or displayed in a float, see [configuration](../README.md#configuration)).

## Lua Helpers

`legendary.nvim` provides some helper functions for defining lazily-evaluated
keymaps.

### `lazy`

Returns a function that references another function with static arguments passed.

**Usage:**

```lua
local h = require('legendary.helpers')
h.lazy(my_function, 'arg1', 'arg2')
-- returns a *new function* equivalent to:
function()
  return my_function('arg1', 'arg2')
end
```

### `lazy_required_fn`

Returns a function that lazily references a function in another plugin or Lua module. It is
able to access functions nested in the module table using dot-notation. This helper can also
handle passing static arguments.

**Basic usage:**

```lua
local h = require('legendary.helpers')
h.lazy_required_fn('telescope.builtin', 'find_files')
-- returns a *new function* equivalent to:
function()
  return require('telescope.builtin').find_files()
end
```

**Passing static arguments:**

```lua
local h = require('legendary.helpers')
h.lazy_required_fn('telescope.builtin', 'find_files', { cwd_only = true })
-- returns a *new function* equivalent to:
function()
  return require('telescope.builtin').find_files({ cwd_only = true })
end
```

**Referencing functions nested within a module table:**

```lua
local h = require('legendary.helpers')
h.lazy_required_fn('neotest', 'run.run')
-- returns a *new function* equivalent to:
function()
  return require('neotest').run.run()
end
```

**Passing multiple arguments:**

```lua
local h = require('legendary.helpers')
h.lazy_required_fn('myplugin', 'somefunction', 'arg1', 'arg2', 'arg3')
-- returns a *new function* equivalent to:
function()
  return require('myplugin').somefunction('arg1', 'arg2', 'arg3')
end
```

### `split_then`

Returns a function that creates a new split, then calls the passed function.

**Usage:**

```lua
local h = require('legendary.helpers')
h.split_then(my_function)
-- returns a *new function* equivalent to:
function()
  vim.cmd.split()
  return my_function()
end
```

### `vsplit_then`

Returns a function that creates a new vertical split, then calls the passed function.

**Usage:**

```lua
local h = require('legendary.helpers')
h.vsplit_then(my_function)
-- returns a *new function* equivalent to:
function()
  vim.cmd.vsplit()
  return my_function()
end
```

# Composition

Helpers can be composed together to create complex keymaps.

**Example:**

```lua
local h = require('legendary.helpers')
-- lazily create a vertical split, then use Telescope.nvim to
-- find a file and open it in the new split
h.vsplit_then(h.lazy_required_fn('telescope.builtin', 'find_files'))
```
