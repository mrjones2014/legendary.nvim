local utils = require('legendary.utils')
describe('legendary.utils', function()
  describe('tbl_shallow_eq(item1, item2)', function()
    it("ignored the 'buffer' opt for equality check", function()
      local opts1 = {
        buffer = 1,
        once = true,
      }
      local opts2 = {
        buffer = 2,
        once = true,
      }
      assert(utils.tbl_shallow_eq(opts1, opts2))
    end)

    it('considers empty opts equal', function()
      assert(utils.tbl_shallow_eq({}, {}))
    end)

    it('considers indexed items', function()
      local opts1 = {
        once = true,
        'test an indexed item',
      }
      local opts2 = {
        once = true,
        'test an indexed item',
      }
      assert(utils.tbl_shallow_eq(opts1, opts2))
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
      assert(utils.tbl_shallow_eq(utils.concat_lists(list1, list2), {
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

    it('returns true when items contains a table that is identical except for "buffer" opt', function()
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
      assert(utils.list_contains(items, new_item))
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
