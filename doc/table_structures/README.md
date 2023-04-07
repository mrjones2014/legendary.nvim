# Table Structures

The tables for keymaps, commands, and `augroup`/`autocmd`s are all similar.

Descriptions can be specified either in the top-level `description` property
on each table, or inside the `opts` table as `opts.desc = 'Description goes here'`.

For `autocmd`s, you must include a `description` property for it to appear in the finder.
This is a design decision because keymaps and commands are frequently executed manually,
so they should appear in the finder by default, while executing `autocmd`s manually with
`:doautocmd` is a much less common use-case, so `autocmd`s are hidden from the finder
unless a description is provided.

You can also run `:LegendaryApi`, then search for `/legendary.types` to read the full API
documentation on accepted types.

- [Keymaps](./KEYMAPS.md)
- [Commands](./COMMANDS.md)
- [Functions](./FUNCTIONS.md)
- [`augroup`/`autocmd`s](./AUTOCMDS.md)

## In-Place Item Filters

All items also support a special in-place filtering syntax, so the item can define its own filter.
The `filters` property should be a table defining one or more filters. The table supports
special properties `bt = value` or `buftype = value` to automatically filter by buffer type,
and `ft = value` or `filetype = value` to automatically filter by file type. You may also
include custom filter functions in the `filters` table as a list. For example:

```lua
local keymaps = {
  { '<C-v>', description = 'Open in vertical split', filters = { ft = 'NvimTree' } },
  {
    '<leader>qt',
    description = 'Do something',
    filters = {
      ft = 'Markdown',
      function(item, context)
        -- here, item is the parsed item itself,
        -- context is a context object, see "Filter Context" below
        return myCustomLogic(context)
      end,
    },
  },
}

local commands = {
  { ':Glow', description = 'Preview Markdown with Glow', filters = { ft = 'markdown' } },
  {
    ':Something',
    description = 'Do something',
    filters = {
      function(item, context)
        -- same function signature as keymaps
      end,
    },
  },
}
```

### Filter Context

The `context` table passed to filters contains the following properties:

```lua
{
  buf = number, -- buffer ID
  buftype = string,
  filetype = string,
  mode = string, -- the mode that the UI was triggered from
  cursor_pos = table, -- { row, col }
  marks = table, -- visual mode marks, if applicable; { line, col, line, col }
}
```
