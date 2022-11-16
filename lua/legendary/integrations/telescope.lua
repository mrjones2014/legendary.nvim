local State = require('legendary.data.state')

local M = {}

-- bit of a hack but idk how else to accomplish this

---Get a Telescope.nvim sorter
---@param opts LegendarySorterOpts
---@return Sorter
function M.get_sorter(opts)
  -- sort the existing item list according to opts
  State.items:sort_inplace(opts)
  return require('telescope.sorters').fuzzy_with_index_bias({})
end

return M
