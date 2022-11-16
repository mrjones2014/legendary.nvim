local assert = require('luassert')
local Command = require('legendary.data.command')

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

    it('parses per-mode implementations into a function that handles mode-implementation lookup', function()
      local normal_executed = false
      local visual_executed = false
      local tbl = {
        ':MyCommand',
        {
          n = function()
            normal_executed = true
          end,
          x = function()
            visual_executed = true
          end,
        },
        description = 'Per-mode implementation command',
      }
      local command = Command:parse(tbl):apply()
      assert.are.same(type(command.implementation), 'function')

      vim.cmd('MyCommand')
      assert.True(normal_executed)

      -- switch to visual mode
      vim.cmd('normal v')
      assert.are.same(vim.fn.mode(), 'v')
      -- execute in visual mode
      vim.cmd('MyCommand')
      assert.True(visual_executed)
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

    it('merges opts with default_opts from config', function()
      require('legendary.config').default_opts.commands = { nargs = '?', bang = true }

      local tbl = {
        ':MyCommand [some arg] {another arg}<cr>',
        function() end,
        description = 'My command',
      }
      Command:parse(tbl):apply()
      local commands = vim.api.nvim_get_commands({ builtin = false })
      -- get the version with args, like "MyCommand [some arg] {another arg}"
      local command = vim.tbl_filter(function(cmd)
        return vim.startswith(cmd.name, 'MyCommand') and cmd.name ~= 'MyCommand'
      end, commands)[1]
      assert.are.same(command.nargs, '?')
      assert.True(command.bang)

      -- cleanup
      require('legendary.config').default_opts.commands = {}
    end)
  end)
end)
