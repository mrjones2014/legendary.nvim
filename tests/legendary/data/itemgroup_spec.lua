local assert = require('luassert')
local ItemList = require('legendary.data.itemlist')
local Keymap = require('legendary.data.keymap')
local Command = require('legendary.data.command')
local Function = require('legendary.data.function')
local ItemGroup = require('legendary.data.itemgroup')
local spy = require('luassert.spy')
local match = require('luassert.match')

describe('ItemGroup', function()
  describe('parse', function()
    it('parses keymaps, commands, and functions into an ItemList', function()
      local keymap_mock = spy.on(Keymap, 'parse')
      local command_mock = spy.on(Command, 'parse')
      local func_mock = spy.on(Function, 'parse')
      local itemlist_mock = spy.on(ItemList, 'create')

      local input = {
        itemgroup = 'Test item group...',
        keymaps = {
          { '<leader>t', description = 'Do something' },
        },
        commands = {
          { ':MyCommand', description = 'Do something' },
        },
        funcs = {
          { function() end, description = 'Do something' },
        },
      }

      ItemGroup:parse(input)

      assert.spy(keymap_mock).was.called_with(match.is_table(), input.keymaps[1])
      assert.spy(command_mock).was.called_with(match.is_table(), input.commands[1])
      assert.spy(func_mock).was.called_with(match.is_table(), input.funcs[1])
      assert.spy(itemlist_mock).was.called_with(match.is_table())
    end)
  end)
end)
