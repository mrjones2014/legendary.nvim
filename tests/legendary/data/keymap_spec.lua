local assert = require('luassert')
local Keymap = require('legendary.data.keymap')

describe('Keymap', function()
  describe('parse', function()
    it('parses basic keymaps with string implementations', function()
      local tbl = { '<leader>f', ':SomeCommand', description = 'Some command', opts = { remap = false } }
      local keymap = Keymap:parse(tbl)
      assert.are.same(keymap.keys, tbl[1])
      assert.are.same(keymap.description, tbl.description)
      assert.are.same(keymap.opts.noremap, tbl.opts.noremap)
      assert.are.same(keymap.mode_mappings, { n = { implementation = ':SomeCommand' } })
    end)

    it('parses basic keymaps with function implementations', function()
      local tbl = { '<leader>f', function() end, description = 'Some command', opts = { remap = false } }
      local keymap = Keymap:parse(tbl)
      assert.are.same(keymap.keys, tbl[1])
      assert.are.same(keymap.description, tbl.description)
      assert.are.same(keymap.opts.noremap, tbl.opts.noremap)
      assert.are.same(keymap.mode_mappings, { n = { implementation = tbl[2] } })
    end)

    it('correctly parses when tbl has `mode` set', function()
      local tbl = { '<leader>f', ':SomeCommand', description = 'Some command', opts = { remap = false }, mode = 'v' }
      local keymap = Keymap:parse(tbl)
      assert.are.same(keymap.keys, tbl[1])
      assert.are.same(keymap.description, tbl.description)
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

  describe('from_vimscript', function()
    local cmds = {
      ['map'] = { mode = { 'n', 'v', 's', 'o' }, remap = true },
      ['nmap'] = { mode = { 'n' }, remap = true },
      ['vmap'] = { mode = { 'v' }, remap = true },
      ['smap'] = { mode = { 's' }, remap = true },
      ['xmap'] = { mode = { 'x' }, remap = true },
      ['omap'] = { mode = { 'o' }, remap = true },
      ['map!'] = { mode = { 'i', 'c' }, remap = true },
      ['imap'] = { mode = { 'i' }, remap = true },
      ['lmap'] = { mode = { 'l' }, remap = true },
      ['cmap'] = { mode = { 'c' }, remap = true },
      ['tmap'] = { mode = { 't' }, remap = true },
      ['noremap '] = { mode = { 'n', 'v', 's', 'o' }, remap = false },
      ['nnoremap'] = { mode = { 'n' }, remap = false },
      ['vnoremap'] = { mode = { 'v' }, remap = false },
      ['snoremap'] = { mode = { 's' }, remap = false },
      ['xnoremap'] = { mode = { 'x' }, remap = false },
      ['onoremap'] = { mode = { 'o' }, remap = false },
      ['noremap!'] = { mode = { 'i', 'c' }, remap = false },
      ['inoremap'] = { mode = { 'i' }, remap = false },
      ['lnoremap'] = { mode = { 'l' }, remap = false },
      ['cnoremap'] = { mode = { 'c' }, remap = false },
      ['tnoremap'] = { mode = { 't' }, remap = false },
    }

    local args_data = {
      buffer = { buffer = vim.api.nvim_get_current_buf() },
      nowait = { nowait = true },
      silent = { silent = true },
      expr = { expr = true },
      unique = { unique = true },
    }

    -- This function clones the array t and appends the item new to it.
    local function append(t, new)
      local clone = {}
      for _, item in ipairs(t) do
        clone[#clone + 1] = item
      end
      clone[#clone + 1] = new
      return clone
    end

    -- Yields combinations of non-repeating items of tbl.
    -- tbl is the source of items,
    -- sub is a combination of items that all yielded combination ought to contain,
    -- min it the minimum key of items that can be added to yielded combinations.
    local function unique_combinations(tbl, sub, min)
      sub = sub or {}
      min = min or 1
      return coroutine.wrap(function()
        if #sub > 0 then
          coroutine.yield(sub) -- yield short combination.
        end
        if #sub < #tbl then
          for i = min, #tbl do -- iterate over longer combinations.
            for combo in unique_combinations(tbl, append(sub, tbl[i]), i + 1) do
              coroutine.yield(combo)
            end
          end
        end
      end)
    end

    local all_arg_combos = {}
    for combo in unique_combinations(vim.tbl_keys(args_data)) do
      table.insert(all_arg_combos, combo)
    end

    it('should parse vimscript keymaps and set mode and opts correctly', function()
      for cmd, mode_remap in pairs(cmds) do
        for _, args in ipairs(all_arg_combos) do
          -- set up expected data
          local args_formatted = table.concat(
            vim.tbl_map(function(arg_str)
              return string.format('<%s>', arg_str)
            end, args),
            ' '
          )
          local map_cmd = string.format('%s %s <leader>t :SomeCommand<CR>', cmd, args_formatted)
          local expected_opts = {}
          expected_opts.remap = mode_remap.remap
          for _, arg in ipairs(args) do
            expected_opts = vim.tbl_extend('force', expected_opts, args_data[arg])
          end

          local keymap = Keymap:from_vimscript(map_cmd, 'Some command mapping')
          assert.are.same(keymap.opts, expected_opts)
          for _, mode in ipairs(mode_remap.mode) do
            assert.is_not_nil(keymap.mode_mappings[mode])
            assert.are.same(keymap.mode_mappings[mode].implementation, ':SomeCommand<CR>')
          end
        end
      end
    end)
  end)
end)
