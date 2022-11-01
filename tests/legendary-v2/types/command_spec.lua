local assert = require('luassert')
local Command = require('legendary-v2.types.command')

describe('Command', function()
  describe('parse', function()
    it('parses basic commands with string implementations', function()
      local tbl = {
        ':MyCommand [some_arg]',
        ':SomeOtherCommand',
        description = 'My command',
        unfinished = true,
        opts = { bang = true, nargs = '?' },
      }
      local command = Command:parse(tbl)
      assert.are.same(command.cmd, tbl[1])
      assert.are.same(command.implementation, tbl[2])
      assert.are.same(command.description, tbl.description)
      assert.are.same(command.opts, { bang = true, nargs = '?' })
      assert.True(command.unfinished)
    end)

    it('parses basic commands with function implementations', function()
      local tbl = {
        ':MyCommand [some_arg]',
        function() end,
        description = 'My command',
        unfinished = true,
        opts = { bang = true, nargs = '?' },
      }
      local command = Command:parse(tbl)
      assert.are.same(command.cmd, tbl[1])
      assert.are.same(command.implementation, tbl[2])
      assert.are.same(command.description, tbl.description)
      assert.are.same(command.opts, { bang = true, nargs = '?' })
      assert.True(command.unfinished)
    end)
  end)

  describe('apply', function()
    it('creates user commands for basic commands', function()
      local tbl = {
        ':MyCommand',
        function() end,
        description = 'My command',
      }
      Command:parse(tbl):apply()
      local commands = vim.api.nvim_get_commands({ builtin = false })
      assert.are.same(commands.MyCommand.name, 'MyCommand')
    end)

    it(
      'sanitizes leading :, trailng <cr> and any argument placeholders properly when registering the command',
      function()
        local tbl = {
          ':MyCommand [some arg] {another arg}<cr>',
          function() end,
          description = 'My command',
          opts = { nargs = '*' },
        }
        Command:parse(tbl):apply()
        local commands = vim.api.nvim_get_commands({ builtin = false })
        assert.are.same(commands.MyCommand.name, 'MyCommand')
      end
    )
  end)
end)
