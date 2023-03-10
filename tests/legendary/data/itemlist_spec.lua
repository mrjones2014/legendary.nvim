local assert = require('luassert')
local Toolbox = require('legendary.toolbox')
local ItemList = require('legendary.data.itemlist')
local Keymap = require('legendary.data.keymap')
local Command = require('legendary.data.command')
local Executor = require('legendary.api.executor')

describe('ItemList', function()
  describe('add', function()
    it('adds valid items', function()
      local keymap = Keymap:parse({ '<leader><leader>', function() end, description = 'test' })
      local list = ItemList:create()
      list:add({ keymap })
      assert.are.same(keymap, list.items[1])
    end)

    it('excludes items without descriptions', function()
      local keymap = Keymap:parse({ '<leader><leader>', function() end })
      local list = ItemList:create()
      list:add({ keymap })
      assert.are.same(#list.items, 0)
    end)

    it('excludes items already contained in the list', function()
      local keymap = Keymap:parse({ '<leader><leader>', function() end, description = 'test' })
      local list = ItemList:create()
      list:add({ keymap })
      assert.are.same(keymap, list.items[1])
      assert.are.same(#list.items, 1)
    end)

    it('excludes items that are hidden', function()
      local keymap = Keymap:parse({ '<leader><leader>', function() end, hide = true, description = 'test' })
      local list = ItemList:create()
      list:add({ keymap })
      assert.are.same(#list.items, 0)
    end)
  end)

  describe('filter', function()
    it('filters items with a single filter', function()
      local keymap = Keymap:parse({ '<leader><leader>', function() end, description = 'test func' })
      local command = Command:parse({ ':MyCommand', function() end, description = 'test cmd' })
      local list = ItemList:create()
      list:add({ keymap, command })
      local filtered = list:filter(Toolbox.is_keymap, {})
      assert.are.same(#filtered, 1)
      assert.are.same(filtered[1], keymap)
    end)

    it('filters items with multiple filters', function()
      local keymap = Keymap:parse({ '<leader><leader>', function() end, description = 'test func' })
      local keymap2 = Keymap:parse({ '<leader><leader>', function() end, description = 'test func 2' })
      local command = Command:parse({ ':MyCommand', function() end, description = 'test cmd' })
      local list = ItemList:create()
      list:add({ keymap, keymap2, command })
      local filtered = list:filter({
        Toolbox.is_keymap,
        function(item)
          return item.description == keymap.description
        end,
      }, {})
      assert.are.same(#filtered, 1)
      assert.are.same(filtered[1], keymap)
    end)

    it('filters by filetype with a context', function()
      local buf = vim.api.nvim_list_bufs()[1]
      local keymap = Keymap:parse({
        '<leader><leader>',
        function() end,
        description = 'test',
        filters = { filetype = vim.api.nvim_buf_get_option(buf, 'filetype') },
      })
      local keymap2 = Keymap:parse({
        '<leader><leader>',
        function() end,
        description = 'test 2',
        filters = { filetype = { 'test2', 'test3' } },
      })
      local list = ItemList:create()
      list:add({ keymap, keymap2 })
      local context = Executor.build_context(buf)
      local filtered = list:filter({}, context)
      assert.are.same(#filtered, 1)
      assert.are.same(filtered[1], keymap)
    end)

    it('filters by buftype with a context', function()
      local buf = vim.api.nvim_list_bufs()[1]
      vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
      local keymap = Keymap:parse({
        '<leader><leader>',
        function() end,
        description = 'test',
        filters = { buftype = 'nofile' },
      })
      print('!!!!!!!!!!', vim.api.nvim_buf_get_option(buf, 'buftype'))
      local keymap2 = Keymap:parse({
        '<leader><leader>',
        function() end,
        description = 'test 2',
        filters = { buftype = { 'test', 'test2' } },
      })
      local list = ItemList:create()
      list:add({ keymap, keymap2 })
      local context = Executor.build_context(buf)
      local filtered = list:filter({}, context)
      assert.are.same(#filtered, 1)
      assert.are.same(filtered[1], keymap)
    end)

    it('filters with custom functions with a context', function()
      local buf = vim.api.nvim_list_bufs()[1]
      local keymap = Keymap:parse({
        '<leader><leader>',
        function() end,
        description = 'test',
        filters = {
          function(_, context)
            return context.buf == buf
          end,
        },
      })
      local keymap2 = Keymap:parse({
        '<leader><leader>',
        function() end,
        description = 'test 2',
        filters = {
          function(_, _)
            return false
          end,
        },
      })
      local list = ItemList:create()
      list:add({ keymap, keymap2 })
      local context = Executor.build_context(buf)
      local filtered = list:filter({}, context)
      assert.are.same(#filtered, 1)
      assert.are.same(filtered[1], keymap)
    end)
  end)
end)
