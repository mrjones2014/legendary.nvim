local Log = require('legendary.log')

return function()
  local has_lazy, _ = pcall(require, 'lazy')
  if not has_lazy then
    Log.warn("lazy.nvim integration is enabled, but cannot `require('lazy')`, aborting.")
    return
  end

  local LazyNvimConfig = require('lazy.core.config')
  local Handler = require('lazy.core.handler')
  local Plugin = require('lazy.core.plugin')
  for _, plugin in pairs(LazyNvimConfig.plugins) do
    local keys = Handler.handlers.keys:_values(Plugin.values(plugin, 'keys', true), plugin)
    for _, keymap in pairs(keys) do
      if keymap.desc and #keymap.desc > 0 then
        -- we don't need the implementation, since
        -- lazy.nvim will have already bound it. We
        -- just need the description-only item to appear
        -- in the legendary.nvim finder.
        local legendary_keymap = {
          -- for backwards compatibility, if keymap.lhs is missing, using an old lazy.nvim so it will be keymap[1]
          keymap.lhs or keymap[1],
          description = keymap.desc,
          mode = keymap.mode, ---@type string|string[]|nil
        }
        require('legendary').keymap(legendary_keymap)
      end
    end
  end
end
