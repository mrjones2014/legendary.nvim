local assert = require('luassert')
local Autocmd = require('legendary-v2.types.autocmd')

describe('Autocmd', function()
  describe('parse', function()
    it('parses basic autocmds with string event and string implementation', function()
      local tbl = {
        'BufEnter',
        ':SomeCommand<CR>',
        opts = {
          pattern = '*.json',
        },
      }
      local autocmd = Autocmd:parse(tbl)
      assert.are.same(autocmd.events, { tbl[1] })
      assert.are.same(autocmd.implementation, tbl[2])
      assert.are.same(autocmd.opts, { pattern = '*.json' })
    end)

    it('parses basic autocmds with string event and function implementation', function()
      local tbl = {
        'BufEnter',
        function() end,
        opts = {
          pattern = '*.json',
        },
      }
      local autocmd = Autocmd:parse(tbl)
      assert.are.same(autocmd.events, { tbl[1] })
      assert.are.same(autocmd.implementation, tbl[2])
      assert.are.same(autocmd.opts, { pattern = '*.json' })
    end)

    it('parses basic autocmds with table of events and string implementation', function()
      local tbl = {
        { 'BufEnter', 'BufLeave' },
        ':SomeCommand<CR>',
        opts = {
          pattern = '*.json',
        },
      }
      local autocmd = Autocmd:parse(tbl)
      assert.are.same(autocmd.events, { tbl[1][1], tbl[1][2] })
      assert.are.same(autocmd.implementation, tbl[2])
      assert.are.same(autocmd.opts, { pattern = '*.json' })
    end)

    it('parses basic autocmds with table of events and function implementation', function()
      local tbl = {
        { 'BufEnter', 'BufLeave' },
        function() end,
        opts = {
          pattern = '*.json',
        },
      }
      local autocmd = Autocmd:parse(tbl)
      assert.are.same(autocmd.events, { tbl[1][1], tbl[1][2] })
      assert.are.same(autocmd.implementation, tbl[2])
      assert.are.same(autocmd.opts, { pattern = '*.json' })
    end)
  end)

  describe('apply', function()
    it('creates autocmds with string implementations', function()
      local group = vim.api.nvim_create_augroup('_LegendaryAutocmdTest_', { clear = true })
      local tbl = {
        'BufEnter',
        ':SomeCommand<CR>',
        opts = {
          pattern = '*.json',
          group = group,
        },
      }
      Autocmd:parse(tbl):apply()
      local autocmd = vim.api.nvim_get_autocmds({
        event = 'BufEnter',
        group = group,
        pattern = '*.json',
      })[1]
      assert.are.same(autocmd.command, tbl[2])
    end)

    it('creates autocmds with function implementations', function()
      local group = vim.api.nvim_create_augroup('_LegendaryAutocmdTest_', { clear = true })
      local tbl = {
        'BufEnter',
        function() end,
        opts = {
          pattern = '*.json',
          group = group,
        },
      }
      Autocmd:parse(tbl):apply()
      local autocmd = vim.api.nvim_get_autocmds({
        event = 'BufEnter',
        group = group,
        pattern = '*.json',
      })[1]
      assert.are.same(autocmd.callback, tbl[2])
    end)
  end)
end)
