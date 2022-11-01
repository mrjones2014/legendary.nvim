local assert = require('luassert')
local Keymap = require('legendary-v2.types.keymap')

describe('Keymap', function()
  describe('parsing', function()
    it('parses basic keymaps with string implementations', function()
      local tbl = { '<leader>f', ':SomeCommand', description = 'Some command', opts = { remap = false } }
      local keymap = Keymap:parse(tbl)
      assert.are.same(keymap.keys, tbl[1])
      assert.are.same(keymap.description, tbl.description)
      assert.are.same(keymap.kind, 'legendary.keymap')
      assert.are.same(keymap.opts.noremap, tbl.opts.noremap)
      assert.are.same(keymap.mode_mappings, { n = { implementation = ':SomeCommand' } })
    end)

    it('parses basic keymaps with function implementations', function()
      local tbl = { '<leader>f', function() end, description = 'Some command', opts = { remap = false } }
      local keymap = Keymap:parse(tbl)
      assert.are.same(keymap.keys, tbl[1])
      assert.are.same(keymap.description, tbl.description)
      assert.are.same(keymap.kind, 'legendary.keymap')
      assert.are.same(keymap.opts.noremap, tbl.opts.noremap)
      assert.are.same(keymap.mode_mappings, { n = { implementation = tbl[2] } })
    end)

    it('correctly parses when tbl has `mode` set', function()
      local tbl = { '<leader>f', ':SomeCommand', description = 'Some command', opts = { remap = false }, mode = 'v' }
      local keymap = Keymap:parse(tbl)
      assert.are.same(keymap.keys, tbl[1])
      assert.are.same(keymap.description, tbl.description)
      assert.are.same(keymap.kind, 'legendary.keymap')
      assert.are.same(keymap.opts.noremap, tbl.opts.noremap)
      assert.are.same(keymap.mode_mappings, { v = { implementation = ':SomeCommand' } })
    end)

    it('correctly parses per-mode mappings', function()
      local tbl = {
        '<leader>f',
        {
          n = ':NormalMode',
          v = ':VisualMode',
        },
        description = 'Different implementations per mode',
      }
      local keymap = Keymap:parse(tbl)
      assert.are.same(keymap.keys, tbl[1])
      assert.are.same(keymap.description, tbl.description)
      assert.are.same(keymap.kind, 'legendary.keymap')
      assert.are.same(
        keymap.mode_mappings,
        { n = { implementation = ':NormalMode' }, v = { implementation = ':VisualMode' } }
      )
    end)
  end)

  describe('apply', function()
    it('applies keymaps', function()
      Keymap:parse({
        '<leader>t',
        {
          n = function() end,
          v = function() end,
        },
        description = 'LegendaryKeymapTest',
      }):apply()

      local normal_keymap = vim.tbl_filter(function(k)
        return k.desc == 'LegendaryKeymapTest'
      end, vim.api.nvim_get_keymap('n'))[1]
      assert.are.same(normal_keymap.lhs, string.format('%st', vim.g.mapleader or '\\'))
      assert.are.same(type(normal_keymap.callback), 'function')

      local visual_keymap = vim.tbl_filter(function(k)
        return k.desc == 'LegendaryKeymapTest'
      end, vim.api.nvim_get_keymap('v'))[1]
      assert.are.same(visual_keymap.lhs, string.format('%st', vim.g.mapleader or '\\'))
      assert.are.same(type(visual_keymap.callback), 'function')
    end)
  end)
end)
