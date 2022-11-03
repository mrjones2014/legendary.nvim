# Usage Examples

## Filter items by current mode

```lua
require('legendary').find({ filters = { require('legendary.filters').current_mode() } })
```

## Filter items by normal mode

```lua
require('legendary').find({ filters = { require('legendary.filters').mode('n') } })
```

## Filter to only keymaps and by current mode

```lua
require('legendary').find({
  filters = {
    require('legendary.filters').mode('n'),
    require('legendary.filters').keymaps(),
  },
})
```

## Customize select prompt title

```lua
require('legendary').find({ select_prompt = 'Custom prompt' })
-- OR
require('legendary').find({
  filters = { require('legendary.filters').keymaps() },
  select_prompt = function() -- can also be a function
    return string.format('%s | Finding Keymaps', vim.fn.getcwd())
  end,
})
```

## Filter keymaps by normal mode and that start with `<leader>`

```lua
require('legendary').find({
  filters = {
    require('legendary.filters').mode('n'),
    function(item)
      if not string.find(item.kind, 'keymap') then
        return true
      end

      return vim.startswith(item[1], '<leader>')
    end,
  },
})
```

## Filter keymaps by current mode, and only display current mode in first column

```lua
require('legendary').find({
  filters = { require('legendary.filters').current_mode() },
  formatter = function(item, mode)
    local values = require('legendary.ui.format').default_format(item)
    if require('legendary.toolbox').is_keymap(item) then
      values[1] = mode
    end
    return values
  end
})
```
