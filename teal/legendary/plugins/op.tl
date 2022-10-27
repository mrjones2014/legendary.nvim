require('legendary.types')

local COMMANDS = {
  { ':OpSignin', description = '' },
  { ':OpSignout', description = '' },
  { ':OpWhoami', description = '' },
  { ':OpCreate', description = '' },
  { ':OpView', description = '' },
  { ':OpEdit', description = '' },
  { ':OpOpen', description = '' },
  { ':OpInsert', description = '' },
  { ':OpNote', description = '' },
  { ':OpSidebar', description = '' },
  { ':OpAnalyzeBuffer', description = '' },
}

local OP_KEYMAP_DESCRIPTIONS: {string:string} = {
  default_open = 'Open the 1Password item under cursor with default handler',
  open_in_desktop_app = 'Open the 1Password item under cursor in the desktop app',
  edit_in_desktop_app = 'Edit the 1Password item under cursor in the desktop app'
}

local MAPPING_KEYS = vim.tbl_keys(OP_KEYMAP_DESCRIPTIONS)

local record OpConfig
  get_config_immutable: function(): {string: {string: {string: string}}}
end

return function(kind: LegendaryKind|nil): LegendaryPluginData
  local data: LegendaryPluginData = {}

  if not kind or #tostring(kind) == 0 or (not not string.find(kind, 'command')) then
    data.commands = COMMANDS
  end

  if not kind or #tostring(kind) == 0 or (not not string.find(kind, 'keymap')) then
    if vim.api.nvim_buf_get_option(0, 'filetype') ~= '1PasswordSidebar' then
      goto plugin_return
    end

    -- workaround Teal type system for dynamic require
    local dynrequire = require
    local ok, op_config = pcall(dynrequire, 'op.config') as (boolean, OpConfig)
    if not ok then
      goto plugin_return
    end

    local keymaps = op_config.get_config_immutable().sidebar.mappings
    local legendary_keymaps = {}
    for keys, mapping in pairs(keymaps) do
      if type(keys) == 'string' and type(mapping) == 'string' and vim.tbl_contains(MAPPING_KEYS, mapping) then
        table.insert(legendary_keymaps, { keys, description = OP_KEYMAP_DESCRIPTIONS[mapping] })
      end
    end

    data.keymaps = legendary_keymaps
  end

  ::plugin_return::
  return data
end
