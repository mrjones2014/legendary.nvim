local assert = require('luassert')
local Augroup = require('legendary-v2.types.augroup')
local Autocmd = require('legendary-v2.types.autocmd')

describe('Augroup', function()
  describe('parse', function()
    it('parses augroup tables', function()
      local tbl = { name = 'LegendaryTestAugroup', clear = false }
      local augroup = Augroup:parse(tbl)
      assert.are.same(augroup.name, tbl.name)
      assert.are.same(augroup.kind, 'legendary.augroup')
      assert.False(augroup.clear)
    end)

    it('parses augroups with autocmds', function()
      local tbl = {
        name = 'LegendaryTestAugroup',
        clear = true,
        {
          'BufEnter',
          ':SomeCommand<CR>',
          opts = {
            pattern = '*.json',
          },
        },
      }
      local augroup = Augroup:parse(tbl)
      assert.are.same(augroup.name, tbl.name)
      assert.are.same(augroup.kind, 'legendary.augroup')
      assert.True(augroup.clear)
      assert.are.same(#augroup, 1)
      assert.are.same(augroup[1].class, Autocmd)
    end)
  end)

  describe('apply', function()
    it('creates augroup and sets group on contained autocmds', function()
      local tbl = {
        name = 'LegendaryTestAugroup',
        clear = true,
        {
          'VimEnter',
          ':SomeCommand<CR>',
          opts = {
            pattern = '*.json',
          },
        },
      }
      Augroup:parse(tbl):apply()
      local autocmd = vim.api.nvim_get_autocmds({
        event = 'VimEnter',
      })[1]

      assert.not_Nil(autocmd.group)
      assert.are.same(type(autocmd.group), 'number')
      assert.are.same(autocmd.group_name, tbl.name)
    end)
  end)
end)
