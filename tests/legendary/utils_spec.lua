local utils = require('legendary.utils')
describe('legendary.utils', function()
  describe('tbl_deep_eq(item1, item2)', function()
    it('considers empty opts equal', function()
      assert(utils.tbl_deep_eq({}, {}))
    end)

    it('considers indexed items', function()
      local opts1 = {
        'some item',
        some_prop = true,
        'test an indexed item',
        'test another indexed item',
      }
      local opts2 = {
        'some item',
        some_prop = true,
        'test an indexed item',
        'test another indexed item',
      }
      assert(utils.tbl_deep_eq(opts1, opts2))
    end)

    it('considers nested tables and when keys aren\'t in the same order', function()
      local opts1 = {
        'some item',
        'test an indexed item',
        'test another indexed item',
        opts = {
          buffer = 1,
          silent = true,
        }
      }
      local opts2 = {
        'some item',
        'test an indexed item',
        'test another indexed item',
        opts = {
          silent = true,
          buffer = 1,
        }
      }
      assert(utils.tbl_deep_eq(opts1, opts2))
    end)
  end)

  describe('concat_lists(tbl1, tbl2)', function()
    it('concats two list-like tables together', function()
      local list1 = {
        'item 1',
        'item 2',
        'item 3',
      }
      local list2 = {
        'item 4',
        'item 5',
        'item 6',
      }
      assert(utils.tbl_deep_eq(utils.concat_lists(list1, list2), {
        'item 1',
        'item 2',
        'item 3',
        'item 4',
        'item 5',
        'item 6',
      }))
    end)
  end)

  describe('list_contains(items, new_item)', function()
    it('returns true when items contains an identical item to new_item', function()
      local new_item = {
        ':SomeCommand',
        'lua print("this is a command")',
        description = 'A command that prints a string',
      }
      local items = { new_item }
      assert(utils.list_contains(items, new_item))
    end)

    it('returns false when items contains a table that is identical except for "buffer" opt', function()
      local item = {
        'FileType',
        ':setlocal conceallevel=0',
        opts = {
          buffer = 2,
          pattern = { 'json', 'jsonc' },
        },
      }
      local new_item = vim.deepcopy(item)
      new_item.opts.buffer = 1
      local items = { item }
      assert(not utils.list_contains(items, new_item))
    end)

    it('returns false when items are completely different', function()
      local item = {
        'SomeItem',
        some_property = 7,
      }
      local new_item = { name = 'a different item' }
      local items = { item }
      assert(not utils.list_contains(items, new_item))
    end)
  end)

  describe('strip_leading_cmd_char', function()
    it('when there is no leading cmd char, returns identity', function()
      local str = 'some str'
      assert(str == utils.strip_leading_cmd_char(str))
    end)

    it('stips leading : cmd char', function()
      local str = ':SomeCommand'
      assert(utils.strip_leading_cmd_char(str) == 'SomeCommand')
    end)

    it('stips leading <CMD> cmd char', function()
      local str = '<CMD>SomeCommand'
      assert(utils.strip_leading_cmd_char(str) == 'SomeCommand')
    end)

    it('stips leading <cmd> cmd char', function()
      local str = '<cmd>SomeCommand'
      assert(utils.strip_leading_cmd_char(str) == 'SomeCommand')
    end)
  end)
end)
