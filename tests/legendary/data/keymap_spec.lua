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

    it('for description-only keymaps, mode_mappings is assigned to a list of the modes', function()
      local tbl = { '<leader>f', description = 'test', mode = { 'n', 'v' } }
      local keymap = Keymap:parse(tbl)
      assert.are.same(keymap.keys, tbl[1])
      assert.are.same(keymap.description, tbl.description)
      assert.are.same(keymap.mode_mappings, tbl.mode)
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

      ---@type table
      local normal_keymap = vim.tbl_filter(function(k)
        return k.desc == 'LegendaryKeymapTest'
      end, vim.api.nvim_get_keymap('n'))[1]
      assert.are.same(normal_keymap.lhs, string.format('%st', vim.g.mapleader or '\\'))
      assert.are.same(type(normal_keymap.callback), 'function')

      ---@type table
      local visual_keymap = vim.tbl_filter(function(k)
        return k.desc == 'LegendaryKeymapTest'
      end, vim.api.nvim_get_keymap('v'))[1]
      assert.are.same(visual_keymap.lhs, string.format('%st', vim.g.mapleader or '\\'))
      assert.are.same(type(visual_keymap.callback), 'function')
    end)

    it('merges opts with default_opts from config', function()
      require('legendary.config').default_opts.keymaps = { silent = true, nowait = true }

      Keymap:parse({
        '<leader>t',
        {
          n = function() end,
          v = function() end,
        },
        description = 'LegendaryKeymapTest',
      }):apply()

      ---@type table
      local normal_keymap = vim.tbl_filter(function(k)
        return k.desc == 'LegendaryKeymapTest'
      end, vim.api.nvim_get_keymap('n'))[1]
      assert.are.same(normal_keymap.silent, 1)
      assert.are.same(normal_keymap.nowait, 1)

      ---@type table
      local visual_keymap = vim.tbl_filter(function(k)
        return k.desc == 'LegendaryKeymapTest'
      end, vim.api.nvim_get_keymap('v'))[1]
      assert.are.same(visual_keymap.silent, 1)
      assert.are.same(visual_keymap.nowait, 1)

      -- cleanup
      require('legendary.config').default_opts.keymaps = {}
    end)
  end)

  describe('from_vimscript', function()
    -- map of keymapping cmds to the mode(s) they indicate and whether it indicates remap or noremap
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

    -- map of argument names to their resulting `opts` values
    local args_data = {
      buffer = { buffer = vim.api.nvim_get_current_buf() },
      nowait = { nowait = true },
      silent = { silent = true },
      expr = { expr = true },
      unique = { unique = true },
    }

    ---Generate all combinations for any number of items from 1 to #values
    ---@generic T
    ---@param values T[]
    ---@param sub T[]
    ---@param min integer
    ---@overload fun(values:any[]):any[]
    ---@return fun(...):...T
    local function unique_combinations(values, sub, min)
      sub = sub or {}
      min = min or 1
      return coroutine.wrap(function()
        if #sub > 0 then
          coroutine.yield(sub) -- yield short combination.
        end
        if #sub < #values then
          for i = min, #values do -- iterate over longer combinations.
            local newsub = vim.deepcopy(sub)
            table.insert(newsub, values[i])
            for combo in unique_combinations(values, newsub, i + 1) do
              coroutine.yield(combo)
            end
          end
        end
      end)
    end

    -- all generate all combinations of any number of arguments,
    -- starting with no arguments
    local all_arg_combos = { {} }
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

          local keymap, input = Keymap:from_vimscript(map_cmd, 'Some command mapping')
          assert.are.same(input, {
            '<leader>t',
            ':SomeCommand<CR>',
            description = 'Some command mapping',
            opts = expected_opts,
            mode = mode_remap.mode,
          })
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
