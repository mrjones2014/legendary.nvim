---[[
--Courtesy of the awesome work in Nightfox.nvim
--https://github.com/EdenEast/nightfox.nvim/blob/main/lua/nightfox/lib/deprecation.lua
--]
local M = {
  _list = { { 'legendary.nvim\n', 'Question' }, { 'The following have been ' }, { 'deprecated:\n', 'WarningMsg' } },
  _has_registered = false,
  _has_flushed = false,
}

function M.write(...)
  for _, e in ipairs({ ... }) do
    local chunk = e
    if type(chunk) == 'string' then
      chunk = { chunk }
    end

    chunk[1] = chunk[1] .. ' '
    table.insert(M._list, chunk)
  end

  M._list[#M._list][1] = M._list[#M._list][1] .. '\n'

  if not M._has_registered then
    local augroup = vim.api.nvim_create_augroup('LegendaryNvimDeprecations', { clear = true })

    vim.api.nvim_create_autocmd('VimEnter', {
      group = augroup,
      once = true,
      command = [[lua require("legendary.deprecate").flush()]],
    })

    M._has_registered = true
  end

  -- return M so it can be chained
  return M
end

function M.flush()
  if not M._has_flushed then
    M.write('See', { 'https://github.com/mrjones2014/legendary.nvim', 'Title' }, 'for more information.')
  end

  M._has_flushed = true

  vim.api.nvim_echo(M._list, true, {})
  return M
end

function M.flush_if_vimenter()
  if M._has_registered then
    M.flush()
  end
end

---Check config for deprecated options,
---and map them to the new options.
---@param cfg LegendaryConfig
---@return LegendaryConfig
function M.check_config(cfg)
  ---@diagnostic disable

  if cfg.most_recent_items_at_top ~= nil then
    M.write(
      { 'config.most_recent_items_at_top', 'WarningMsg' },
      'has been moved to',
      { 'config.sort.most_recent_first' }
    )
    cfg.sort.most_recent_first = cfg.most_recent_items_at_top
  end

  ---@diagnostic enable

  return cfg
end

return M
