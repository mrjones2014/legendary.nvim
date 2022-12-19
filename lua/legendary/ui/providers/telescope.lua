local Config = require('legendary.config')
local Picker = require('telescope.pickers')
local Finder = require('telescope.finders')
local Actions = require('telescope.actions')
local PickerState = require('telescope.actions.state')

local M = {}

M.default_config = {}

local function default_format(item)
  return tostring(item)
end

local function default_config(items, opts, callback)
  local theme = require('telescope.themes').get_dropdown()
  return vim.tbl_deep_extend('force', theme, {
    prompt_title = opts.prompt or ' legendary.nvim ',
    finder = Finder.new_table({
      results = items,
      entry_maker = function(item)
        local formatted = (opts.format_item or default_format)(item)
        return {
          display = formatted,
          ordinal = formatted,
          value = item,
        }
      end,
    }),
    layout_config = {
      prompt_position = 'top',
    },
    sorter = require('telescope.sorters').fuzzy_with_index_bias({}),
    attach_mappings = function(prompt_bufnr)
      Actions.select_default:replace(function()
        local selected = vim.tbl_get(PickerState.get_selected_entry() or {}, 'value')
        Actions.close(prompt_bufnr)
        callback(selected)
      end)

      return true
    end,
    previewer = false,
  })
end

function M.select(items, opts, callback)
  local config = vim.tbl_deep_extend('force', default_config(items, opts, callback), Config.ui.config)
  Picker.new(config, {}):find()
end

return M
