require('legendary.types')

local M = {}

---Merge returned plugin
---@param data LegendaryPluginData
---@return LegendaryPluginData
local function with_defaults(data: LegendaryPluginData): LegendaryPluginData
  return vim.tbl_deep_extend("keep", data or {}, {
    keymaps = {},
    commands = {},
    functions = {},
  }) as LegendaryPluginData
end

local function try_run_plugin(plugin: LegendaryPlugin, kind: LegendaryKind|nil): LegendaryPluginData
  local ok, values = pcall(plugin, kind) as (boolean, LegendaryPluginData)
    print(vim.inspect(ok), vim.inspect(values))
  if not ok then
    return with_defaults()
  end

  return with_defaults(values)
end

local function set_kinds(data: LegendaryPluginData): LegendaryPluginData
  for _, keymap in ipairs(data.keymaps) do
    keymap.kind = 'legendary.keymap'
  end

  for _, command in ipairs(data.commands) do
    command.kind = 'legendary.command'
  end

  for _, func in ipairs(data.functions) do
    func.kind = 'legendary.function'
  end

  return data
end

function M.run_plugins(kind: LegendaryKind|nil): LegendaryPluginData
  local data: LegendaryPluginData = {
    keymaps = {},
    commands = {},
  }

  local plugins = require('legendary.config').plugins
  for plugin_name, enabled in pairs(plugins) do
    if not enabled then
      goto plugins_continue
    end

    -- workaround teal type system for dynamic require
    local dynrequire = require
    local ok, plugin = pcall(dynrequire, string.format('legendary.plugins.%s', plugin_name)) as (boolean, LegendaryPlugin)
    if not ok then
      goto plugins_continue
    end

    local values = try_run_plugin(plugin, kind)
    data.keymaps = vim.list_extend(data.keymaps, values.keymaps)
    data.commands = vim.list_extend(data.commands, values.commands)

    ::plugins_continue::
  end

  return set_kinds(data)
end

return M
