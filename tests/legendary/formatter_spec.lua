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

      for _, item in pairs(items) do
        formatter.update_padding(item)
      end

      local padding = formatter.get_padding()
      assert(#padding == 3)
      assert(padding[1] == #'<leader>c')
      assert(padding[2] == #'lua vim.lsp.buf.definition')
      assert(padding[3] == #'Go to definition with LSP')
    end)
  end)
end)
