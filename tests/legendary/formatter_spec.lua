local formatter = require('legendary.formatter')

describe('formatter', function()
  describe('format(item)', function()
    it('formats properly with default formatter', function()
      -- ensure using default function
      require('legendary.config').formatter = nil
      local item = { '<leader>c', ':CommentToggle<CR>', description = 'Toggle comment', mode = { 'n', 'v' } }
      local formatted = formatter.format(item)
      assert(formatted == 'n, v │ <leader>c │ Toggle comment')
    end)

    it('formats properly with custom formatter function', function()
      require('legendary.config').formatter = function(item)
        return {
          item[1],
          item[2],
          table.concat(item.mode, '│'),
        }
      end
      local item = { '<leader>c', ':CommentToggle<CR>', description = 'Toggle comment', mode = { 'n', 'v' } }
      local formatted = formatter.format(item)
      assert(formatted == '<leader>c │ :CommentToggle<CR> │ n│v')
    end)

    it('formats properly with a different number of columns', function()
      require('legendary.config').formatter = function(item)
        return {
          item[1],
          item[2],
          table.concat(item.mode, '│'),
          item.description,
        }
      end
      local item = { '<leader>c', ':CommentToggle<CR>', description = 'Toggle comment', mode = { 'n', 'v' } }
      local formatted = formatter.format(item)
      assert(formatted == '<leader>c │ :CommentToggle<CR> │ n│v │ Toggle comment')
    end)
  end)

  describe('update_padding(item)', function()
    before_each(function()
      formatter.__clear_padding()
    end)

    it('sets padding to the length of the longest value in each column', function()
      require('legendary.config').formatter = function(item)
        return {
          item[1],
          item[2],
          item.description,
        }
      end

      local items = {
        { '<leader>c', ':CommentToggle<CR>', description = 'Toggle comment' },
        { '<leader>s', ':wa<CR>', description = 'Write all buffers' },
        { 'gd', 'lua vim.lsp.buf.definition', description = 'Go to definition with LSP' },
      }

      vim.tbl_map(function(item)
        formatter.update_padding(item)
      end, items)

      local padding = formatter.get_padding()
      assert(#padding == 3)
      assert(padding[1] == #'<leader>c')
      assert(padding[2] == #'lua vim.lsp.buf.definition')
      assert(padding[3] == #'Go to definition with LSP')
    end)

    it('computes length correctly when string contains unicode characters', function()
      require('legendary.config').formatter = function(item)
        return {
          item[1],
          item[2],
          item.description,
        }
      end

      local items = {
        { '∆', '', description = '' },
        { '˚', '', description = '' },
        { 'ݑ', '', description = '' },
      }

      vim.tbl_map(function(item)
        formatter.update_padding(item)
      end, items)

      local padding = formatter.get_padding()
      assert(#padding == 1)
      assert(padding[1] == 1)
    end)
  end)

  describe('lpad(str)', function()
    it(
      'padds all strings to have the same length based on the padding table, accounting for unicode characters',
      function()
        require('legendary.config').formatter = function(item)
          return {
            item[1],
            item[2],
            item.description,
          }
        end

        local items = {
          { '<leader>c', ':CommentToggle<CR>', description = 'Toggle comment' },
          { '<leader>s', ':wa<CR>', description = 'Write all buffers' },
          { 'gd', 'lua vim.lsp.buf.definition', description = 'Go to definition with LSP' },
          { '∆', ':echo "test"<CR>', description = 'Contains a triangle' },
          { '˚', ':lua print("test")<CR>', description = 'Contains a unicode dot' },
          { 'ݑ', ':e<CR>', description = 'Contains a unicode character' },
        }

        vim.tbl_map(function(item)
          formatter.update_padding(item)
        end, items)

        local padded = {}
        local padding = formatter.get_padding()
        vim.tbl_map(function(item)
          table.insert(padded, {
            formatter.rpad(item[1], padding[1]),
            formatter.rpad(item[2], padding[2]),
            formatter.rpad(item[3], padding[3]),
          })
        end, items)

        for i, _ in pairs(padded) do
          if i < #padded then
            assert(formatter.utf8_len(padded[i][1]) == formatter.utf8_len(padded[i + 1][1]))
            assert(formatter.utf8_len(padded[i][2]) == formatter.utf8_len(padded[i + 1][2]))
            assert(formatter.utf8_len(padded[i][3]) == formatter.utf8_len(padded[i + 1][3]))
          end
        end
      end
    )
  end)
end)
