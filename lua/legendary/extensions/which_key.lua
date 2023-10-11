local Log = require('legendary.log')
local util = require('legendary.util.which_key')

---@class LegendaryWhichkeyConfig
---@field auto_register boolean
---@field mappings table[]
---@field opts table
---@field do_binding boolean
---@field use_groups boolean

---@param opts LegendaryWhichkeyConfig
return function(opts)
  local loaded, which_key = pcall(require, 'which-key')

  if loaded then
    local wk = which_key

    if opts then
      if opts.do_binding == nil then
        opts.do_binding = false
      end

      if opts.use_groups == nil then
        opts.use_groups = true
      end

      if #vim.tbl_keys(opts.mappings or {}) > 0 then
        util.bind_whichkey(opts.mappings, opts.opts, opts.do_binding, opts.use_groups)
      end
    end

    local original = wk.register
    local listener = function(whichkey_tbls, whichkey_opts)
      Log.trace('Preparing to register items from which-key.nvim automatically')
      util.bind_whichkey(whichkey_tbls, whichkey_opts, false, opts.use_groups)
      original(whichkey_tbls, whichkey_opts)
      Log.trace('Successfully registered items from which-key.nvim')
    end
    wk.register = listener
  else
    Log.warn(
      'which-key.nvim not available. If you are lazy-loading, be sure that which-key.nvim is added to runtime path '
        .. 'before running legendary.nvim config.'
    )
  end
end
