require('legendary.types')
local M = {}

function M.notify(msg: string, level: integer | nil, title: string | nil)
  level = level or vim.log.levels.ERROR
  title = title or 'legendary.nvim'
  vim.notify(msg, level, { title = title })
end

--- Get visual marks in format {start_line, start_col, end_line, end_col}
--- @return table in format {start_line, start_col, end_line, end_col}
function M.get_marks(): table
  local cursor = vim.api.nvim_win_get_cursor(0)
  local cline, ccol = cursor[1], cursor[2]
  local vline, vcol = vim.fn.line('v'), vim.fn.col('v')
  return { cline, ccol, vline, vcol }
end

--- If item.description is not set,
--- try taking the description from
--- item.opts.desc
---@param item T where T is a LegendaryKeymap, LegendaryCommand or LegendaryAutocmd
---@return T
function M.resolve_description<T>(item: T, fallback: string | nil): T
  if not item or type(item) ~= 'table' then
    return item
  end

  if (item as table).description and #((item as table).description as string) > 0 then
    return item
  end

  if (item as table).opts and ((item as table).opts as table).desc and #(((item as table).opts as table).desc as string) > 0 then
    (item as table).description = ((item as table).opts as table).desc
  end

  if #(((item as table).description or '') as string) == 0 then
    (item as table).description = fallback
  end

  return item
end

--- Check if a LegendaryKeymap has per-mode descriptions set
---@param keymap LegendaryKeymap
---@return boolean true if the keymap has per-mode descriptions set
function M.has_per_mode_description(keymap: LegendaryKeymap): boolean
  if not keymap then
    return false
  end

  if type(keymap[2]) ~= 'table' then
    return false
  end

  for _, impl in pairs(keymap[2] as table) do
    impl = M.resolve_description(impl)
    if #((((impl as table).description) as string | nil) or '') > 0 then
      return true
    end
  end
  return false
end

--- Get resolved LegendaryKeymaps for a LegendaryKeymap
--- that may or may not have per-mode descriptions
--- (and therefore should be treated as separate items)
function M.resolve_with_per_mode_description(keymap: LegendaryKeymap): {LegendaryKeymap}
  if not keymap or type(keymap[2]) ~= 'table' or not M.has_per_mode_description(keymap) then
    return { keymap }
  end

  keymap = M.resolve_description(keymap)

  local resolved_tbls: {LegendaryKeymap} = {}
  for mode, impl in pairs(keymap[2] as table) do
    local resolved_keymap: LegendaryKeymap = { keymap[1], kind = 'legendary.keymap' }
    if type(impl) == 'table' then
      resolved_keymap.opts = vim.tbl_deep_extend(
        'keep',
        ((impl as table).opts or {}) as table,
        keymap.opts or {}
      )
      resolved_keymap.mode = mode as string | {string}
      resolved_keymap.description = (impl as table).description as string
    else
      resolved_keymap.mode = mode as string | {string}
      resolved_keymap.opts = keymap.opts
      resolved_keymap.description = keymap.description
    end

    local fallback_desc = keymap.description or ''
    if #fallback_desc == 0 then
      fallback_desc = (keymap.opts and keymap.opts.desc as string) or nil
    end
    resolved_keymap = M.resolve_description(resolved_keymap, fallback_desc)
    table.insert(resolved_tbls, resolved_keymap)
  end

  return resolved_tbls
end

--- Set visual marks from a table in the format
--- {start_line, start_col, end_line, end_col}
function M.set_marks(visual_selection: table)
  vim.fn.setpos("'<", { 0, visual_selection[1], visual_selection[2], 0 })
  vim.fn.setpos("'>", { 0, visual_selection[3], visual_selection[4], 0 })
end

--- Check if opts lists contain the same opts.
---@param item1 LegendaryItem
---@param item2 LegendaryItem
---@return boolean
function M.tbl_deep_eq(item1: any, item2: any): boolean
  local tbl1 = item1 or {}
  local tbl2 = item2 or {}
  return vim.inspect(tbl1) == vim.inspect(tbl2)
end

--- Check if a list-like table of items already contains an item
---@param items LegendaryItem[]
---@param new_item LegendaryItem
---@return boolean
function M.list_contains<T>(items: {T}, new_item: T): boolean
  for _, item in ipairs(items) do
    if
      (item as table)[1] == (new_item as table)[1]
      and (item as table)[2] == (new_item as table)[2]
      and ((item as table).mode or 'n') == ((new_item as table).mode or 'n')
      and (item as table).description == (new_item as table).description
      and M.tbl_deep_eq((item as table).opts as table, (new_item as table).opts as table)
    then
      return true
    end
  end

  return false
end

--- Check if given item is a user-defined keymap
---@param keymap any
---@return boolean
function M.is_user_keymap(keymap: LegendaryKeymap): boolean
  return not not (
      keymap ~= nil
      and type(keymap) == 'table'
      and type(keymap[1]) == 'string'
      and (type(keymap[2]) == 'string' or type(keymap[2]) == 'function' or type(keymap[2]) == 'table')
    )
end

--- Check if a string represents a visual mode
---@param mode_str string
---@return boolean
function M.is_visual_mode(mode_str: string): boolean
  mode_str = mode_str or ''
  if mode_str == 'nov' or mode_str == 'noV' or mode_str == 'no' then
    return false
  end

  return not not (string.find(mode_str:lower(), 'v') or string.find(mode_str:lower(), '') or mode_str == 'x')
end

--- Check if an item is mapped to a visual mode
---@param item LegendaryItem
---@return boolean
function M.has_visual_mode(item: LegendaryKeymap): boolean
  if type(item.mode) == 'string' then
    return M.is_visual_mode(item.mode as string)
  end

  for _, mode in ipairs((item.mode as {string}) or {}) do
    if M.is_visual_mode(mode) then
      return true
    end
  end

  return false
end

--- Take a `LegendaryItem` and return
--- a list of tables, each table containing
--- the arguments that are to be passed
--- directly into vim.keymap.set
function M.resolve_keymap(keymap: LegendaryKeymap): table
  local resolved_keymaps: {table} = {}
  if type(keymap[2]) == 'table' then
    for mode, impl in pairs(keymap[2] as {string:any}) do
      local inner_map = { keymap[1], impl, mode = mode, opts = keymap.opts, description = keymap.description }
      if type(impl) == 'table' then
        -- if inner map has opts, merge with outer opts, inner opts take precedence
        local inner_opts = vim.tbl_deep_extend('keep', (impl as LegendaryModeMappingOpts).opts or {}, keymap.opts or {})

        -- set defaults
        if inner_opts.silent == nil then
          inner_opts.silent = true
        end

        -- map description to neovim's internal `desc` field
        inner_opts.desc = keymap.description

        inner_map[2] = (impl as LegendaryModeMappingOpts)[1]
        inner_map.opts = inner_opts
      else
        local inner_opts = vim.deepcopy(keymap.opts or {})
        -- set defaults
        if inner_opts.silent == nil then
          inner_opts.silent = true
        end
        -- map description to neovim's internal `desc` field
        inner_opts.desc = keymap.description
        inner_map.opts = inner_opts
      end
      table.insert(resolved_keymaps, { mode or 'n', inner_map[1], inner_map[2], inner_map.opts })
    end

    -- !! it's very important that we return here
    return resolved_keymaps
  end

  if type(keymap[2]) == 'function' and M.has_visual_mode(keymap) then
    local orig = keymap[2] as function(marks: table | nil): nil
    keymap[2] = function(visual_selection: table): nil
      local current_mode = (vim.fn.mode() or '') as string
      if M.is_visual_mode(current_mode) then
        -- ensure marks are set
        local marks = visual_selection or M.get_marks()
        M.set_marks(marks)
        orig(marks)
      else
        orig()
      end
    end
  end

  local opts = vim.deepcopy(keymap.opts or {})
  -- set default options
  if opts.silent == nil then
    opts.silent = true
  end

  -- map description to neovim's internal `desc` field
  opts.desc = opts.desc or keymap.description

  table.insert(resolved_keymaps, { keymap.mode or 'n', keymap[1], keymap[2], opts })
  return resolved_keymaps
end

--- Set the given keymap
---@param keymap LegendaryItem
function M.set_keymap(keymap: LegendaryKeymap)
  if not M.is_user_keymap(keymap) then
    return
  end

  -- if not a keymap the user wants us to bind, bail
  if type(keymap[2]) ~= 'string' and type(keymap[2]) ~= 'function' and type(keymap[2]) ~= 'table' then
    return
  end

  if not vim.keymap or not vim.keymap.set then
    M.notify('Sorry, binding keymaps with legendary.nvim requires Neovim 0.7.0 or higher!')
    return
  end

  for _, args_tbl in pairs(M.resolve_keymap(keymap)) do
    local args = args_tbl as {(string | {string}), string, (string | function()), vim.keymap.SetOptions}
    vim.keymap.set(args[1], args[2], args[3], args[4])
  end
end

--- Strip a leading `:` or `<cmd>` if there is one
---@param cmd_str string
---@return string
function M.strip_leading_cmd_char(cmd_str: string): string
  if type(cmd_str) ~= 'string' then
    return cmd_str
  end

  if cmd_str:sub(1, 5):lower() == '<cmd>' then
    return cmd_str:sub(6)
  elseif cmd_str:sub(1, 1) == ':' then
    return cmd_str:sub(2)
  end

  return cmd_str
end

function M.strip_trailing_cr(cmd_str: string): string
  local cmd = vim.deepcopy(cmd_str)
  if cmd:sub(#cmd - 3):lower() == '<cr>' then
    cmd = cmd:sub(1, #cmd - 4)
  elseif cmd:sub(#cmd - 1):lower() == '\r' then
    cmd = cmd:sub(1, #cmd - 2)
  end
  return cmd
end

function M.append_trailing_cr(cmd_str: string): string
  local cmd = vim.deepcopy(cmd_str)
  if #cmd == #(M.strip_trailing_cr(cmd)) then
    cmd = string.format('%s<CR>', cmd)
  end
  return cmd
end


--- Check if given item is a user-defined function
---@param cmd any
---@return boolean
function M.is_user_function(cmd: LegendaryFunction): boolean
  return not not (
      cmd ~= nil
      and type(cmd) == 'table'
      and type(cmd[1]) == 'function'
      and type(cmd.description) == 'string'
      and cmd.description ~= ''
    )
end

--- Check if given item is a user-defined command
---@param cmd any
---@return boolean
function M.is_user_command(cmd: LegendaryCommand): boolean
  return not not (
      cmd ~= nil
      and type(cmd) == 'table'
      and type(cmd[1]) == 'string'
      and (type(cmd[2]) == 'string' or type(cmd[2]) == 'function')
    )
end

--- Set up the given command
---@param cmd LegendaryItem
function M.set_command(cmd: LegendaryCommand)
  if not M.is_user_command(cmd) then
    return
  end

  local opts = vim.deepcopy(cmd.opts or {}) as {string:any}
  opts.desc = opts.desc or cmd.description

  if opts.buffer ~= nil then
    local buffer = opts.buffer as integer
    opts.buffer = nil
    vim.api.nvim_buf_create_user_command(buffer, M.strip_leading_cmd_char(cmd[1] as string), cmd[2], opts)
  else
    vim.api.nvim_create_user_command(M.strip_leading_cmd_char(cmd[1] as string), cmd[2], opts)
  end
end

--- Check if the given item is a user autocmd
---@param autocmd any
---@return boolean
function M.is_user_autocmd(autocmd: LegendaryAutocmd): boolean
  local first_el_is_autocmd_event = type(autocmd[1]) == 'string'
    and #(autocmd[1] as string) == #M.strip_leading_cmd_char(autocmd[1] as string)

  return not not (
      autocmd ~= nil
      and type(autocmd) == 'table'
      and (first_el_is_autocmd_event or type(autocmd[1]) == 'table')
      and (type(autocmd[2]) == 'string' or type(autocmd[2]) == 'function')
    )
end

--- Set an autocmd
---@param autocmd LegendaryItem the autocmd definition to set
---@param group string override autocmd.opts.group with this value
function M.set_autocmd(autocmd: LegendaryAutocmd, group: string | nil)
  if not M.is_user_autocmd(autocmd) then
    return
  end

  local opts = vim.deepcopy(autocmd.opts or {}) as {string:any}
  if type(autocmd[2]) == 'function' then
    opts.callback = autocmd[2]
  else
    opts.command = autocmd[2]
  end

  opts.group = group or opts.group as string
  vim.api.nvim_create_autocmd(autocmd[1], opts)
end

--- Check if the given item is an augroup
---@param augroup any
---@return boolean
function M.is_user_augroup(augroup: LegendaryAugroup): boolean
  return not not (augroup and augroup.name and #augroup > 0 and M.is_user_autocmd(augroup[1]))
end

--- Get the implementation of an item
---@param item LegendaryItem
---@return string | function
function M.get_definition(item: table, mode: string | nil): string | function(marks: table): nil
  mode = mode or vim.fn.mode() as string
  if M.is_user_function(item as LegendaryFunction) then
    return item[1] as function(marks: table): nil
  end

  if M.is_user_keymap(item as LegendaryKeymap) or M.is_user_autocmd(item as LegendaryAutocmd) then
    local def = (item as table)[2]
    -- if it's a per-mode mapping,
    -- unwrap the table and get the mapping
    -- for current mode
    if type(def) == 'table' then
      def = ((item as table)[2] as table)[mode]
      if def == nil and M.is_visual_mode(mode) then
        def = ((item as table)[2] as table)['x']
      end

      -- if it's a per-mode mapping with per-mode opts
      -- unwrap the inner table
      if type(def) == 'table' then
        def = (def as table)[1]
      end
    end

    return def as string | function(marks: table): nil
  end

  return (item as table)[1] as string | function(marks: table): nil
end

--- Get the resolved opts for a keymap table
---@param item LegendaryItem but specifically a keymap one
---@param mode string
function M.resolve_opts(item: LegendaryItem, mode: string | nil): {string:any}
  if not vim.startswith(item.kind, 'legendary.keymap') then
    return ((item as table).opts as {string:any}) or {}
  end

  local params = M.resolve_keymap(item as LegendaryKeymap)
  local keymap_params = (vim.tbl_filter(function(param_list): boolean
    if type((param_list as table)[1]) == 'string' then
      return (param_list as table)[1] == mode or (param_list as table)[1] == 'x' and M.is_visual_mode(mode)
    else
      return vim.tbl_contains((param_list as {{string}})[1], mode) or (vim.tbl_contains((param_list as {{string}})[1], 'x') and M.is_visual_mode(mode))
    end
  end, params as {string}) as table)[1]
  if keymap_params then
    local keymap_params_array = keymap_params as {{string:any}}
    return keymap_params_array[#keymap_params_array] or {}
  end

  return {}
end

--- Helper function to send <ESC> properly
function M.send_escape_key()
  vim.api.nvim_feedkeys(vim.api.nvim_eval('"\\<esc>"') as string, 'n', true)
end

return M
