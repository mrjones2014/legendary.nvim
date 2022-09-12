local types = require('legendary.types')
local M = {}

local _current_id = 0
local function next_id(): integer
  _current_id = _current_id + 1
  return _current_id
end

local last_used_item: LegendaryItem

local keymaps = require('legendary.config').keymaps
local commands = require('legendary.config').commands
local autocmds = require('legendary.config').autocmds
local functions = require('legendary.config').functions

local utils = require('legendary.utils')

local formatter = require('legendary.formatter')

--- Bind a single keymap with legendary.nvim
---@param keymap LegendaryItem
function M.bind_keymap(keymap: LegendaryKeymap, kind: string | nil)
  keymap = utils.resolve_description(keymap)
  keymap.kind = (kind or 'legendary.keymap') as LegendaryKind
  keymap.id = next_id()
  types.validate_keymap(keymap)

  if not keymap or type(keymap) ~= 'table' then
    utils.notify(string.format('Expected table, got %s', type(keymap)))
    return
  end

  if utils.list_contains(keymaps, keymap) then
    return
  end

  if keymap.opts and (keymap.opts.buffer == 0 or keymap.opts.buffer == true) then
    keymap.opts.buffer = vim.api.nvim_get_current_buf()
  end

  utils.set_keymap(keymap)
  formatter.update_padding(keymap as LegendaryItem)
  for _, resolved_keymap in ipairs(utils.resolve_with_per_mode_description(keymap)) do
    keymap.id = next_id()
    table.insert(keymaps, resolved_keymap)
  end
end

--- Bind a list of keymaps with legendary.nvim
---@param new_keymaps LegendaryItem[]
function M.bind_keymaps(new_keymaps: {LegendaryKeymap}, kind: string | nil)
  if not new_keymaps or type(new_keymaps) ~= 'table' then
    return
  end

  if not vim.tbl_islist(new_keymaps) then
    utils.notify(
      string.format('Expected list-like table, got %s, at require("legendary").bind_keymaps', type(new_keymaps))
    )
    return
  end

  vim.tbl_map(function(keymap: LegendaryKeymap): nil
    M.bind_keymap(keymap, kind)
  end, new_keymaps)
end

--- Bind a single command with legendary.nvim
---@param cmd LegendaryItem
function M.bind_command(cmd: LegendaryCommand, kind: string | nil)
  cmd = utils.resolve_description(cmd)
  cmd.kind = (kind or 'legendary.command') as LegendaryKind
  cmd.id = next_id()
  types.validate_command(cmd)
  if not cmd or type(cmd) ~= 'table' then
    utils.notify(string.format('Expected table, got %s', type(cmd)))
    return
  end

  if cmd.opts and cmd.opts.buffer == 0 then
    cmd.opts.buffer = vim.api.nvim_get_current_buf()
  end

  if utils.list_contains(commands, cmd) then
    return
  end

  utils.set_command(cmd)
  formatter.update_padding(cmd as LegendaryItem)
  table.insert(commands, cmd)
end

--- Bind a list of commands with legendary.nvim
---@param cmds LegendaryItem[]
function M.bind_commands(cmds: {LegendaryCommand}, kind: string | nil)
  if not cmds or type(cmds) ~= 'table' then
    return
  end

  if not vim.tbl_islist(cmds) then
    utils.notify(
      string.format('Expected list-like table, got %s, at require("legendary").bind_commands', type(cmds))
    )
    return
  end

  vim.tbl_map(function(cmd: LegendaryCommand): nil
    M.bind_command(cmd, kind)
  end, cmds)
end

--- Bind a single autocmd with legendary.nvim
---@param autocmd LegendaryItem
local function bind_autocmd(autocmd: LegendaryAutocmd, group: string | nil, kind: string | nil)
  autocmd = utils.resolve_description(autocmd)
  autocmd.kind = (kind or 'legendary.autocmd') as LegendaryKind
  autocmd.id = next_id()
  types.validate_autocmd(autocmd)

  if not vim.api.nvim_create_augroup then
    utils.notify(
      'Sorry, managing autocmds via legendary.nvim is only supported on Neovim 0.7+ (requires `vim.api.nvim_create_augroup` and `vim.api.nvim_create_autocmd` API functions).'
    )
    return
  end

  if not autocmd or type(autocmd) ~= 'table' then
    utils.notify(string.format('Expected table, got %s', type(autocmd)))
    return
  end

  if utils.list_contains(autocmds as {LegendaryAutocmd}, autocmd) then
    return
  end

  if autocmd.opts and autocmd.opts.buffer == 0 then
    autocmd.opts.buffer = vim.api.nvim_get_current_buf()
  end

  utils.set_autocmd(autocmd, group)
  if autocmd.description and #autocmd.description > 0 and not (autocmd.opts or {}).once then
    formatter.update_padding(autocmd as LegendaryItem)
    table.insert(autocmds as {LegendaryAutocmd}, autocmd)
  end
end

--- Bind an augroup of autocmds
---@param augroup LegendaryAugroup
local function bind_augroup(augroup: LegendaryAugroup, kind: string | nil)
  augroup = utils.resolve_description(augroup)
  types.validate_augroup(augroup)
  if not vim.api.nvim_create_augroup then
    utils.notify(
      --luacheck: ignore
      'Sorry, managing autocmds via legendary.nvim is only supported on Neovim 0.7+ (requires `vim.api.nvim_create_augroup` and `vim.api.nvim_create_autocmd` API functions).'
    )
    return
  end

  local group_name = augroup and augroup.name or ''
  if #group_name == 0 then
    utils.notify('augroup must have a name')
    return
  end

  local clear = augroup and augroup.clear
  if clear == nil then
    clear = true
  end

  vim.api.nvim_create_augroup(group_name, { clear = clear })

  for _, autocmd in ipairs(augroup as {LegendaryAutocmd}) do
    autocmd.opts = autocmd.opts or {}
    autocmd.opts.group = group_name
    bind_autocmd(autocmd, group_name, kind)
  end
end

--- Bind a list of mixed augroups and autocmds
---@param au LegendaryAugroup[] | LegendaryItem[]
function M.bind_autocmds(au: table, kind: string | nil)
  if utils.is_user_augroup(au as LegendaryAugroup) then
    bind_augroup(au as LegendaryAugroup)
  elseif utils.is_user_autocmd(au as LegendaryAutocmd) then
    bind_autocmd(au as LegendaryAutocmd)
  else
    vim.tbl_map(function(augroup_or_autocmd: table): nil
      if utils.is_user_augroup(augroup_or_autocmd as LegendaryAugroup) then
        bind_augroup(augroup_or_autocmd as LegendaryAugroup, kind)
      elseif utils.is_user_autocmd(augroup_or_autocmd as LegendaryAutocmd) then
        bind_autocmd(augroup_or_autocmd as LegendaryAutocmd, kind)
      end
    end, au)
  end
end

--- Bind a single function with legendary.nvim
---@param fn LegendaryFunction
function M.bind_function(fn: LegendaryFunction, kind: string | nil)
  fn = utils.resolve_description(fn)
  fn.kind = (kind or 'legendary.function') as LegendaryKind
  fn.id = next_id()
  types.validate_function(fn)

  if not fn or type(fn) ~= 'table' then
    utils.notify(string.format('Expected table, got %s', type(fn)))
    return
  end

  if fn.opts and fn.opts.buffer == 0 then
    fn.opts.buffer = vim.api.nvim_get_current_buf()
  end

  if utils.list_contains(functions, fn) then
    return
  end

  require('legendary.formatter').update_padding(fn as LegendaryItem)
  table.insert(functions, fn)
end

--- Bind a list of functions with legendary.nvim
---@param fns LegendaryFunction[]
function M.bind_functions(fns: {LegendaryFunction}, kind: string | nil)
  if not fns or type(fns) ~= 'table' then
    return
  end

  if not vim.tbl_islist(fns) then
    utils.notify(
      string.format('Expected list-like table, got %s, at require("legendary").bind_commands', type(fns))
    )
    return
  end

  vim.tbl_map(function(fn: LegendaryFunction): nil
    M.bind_function(fn, kind)
  end, fns)
end

--- Find keymaps, commands, or both (both by default)
--- with legendary.nvim. To find only keymaps, pass
--- "keymaps" as a parameter, pass "commands" to find
--- only commands, pass "autocmds" to find only autocmds.
---@param item_kind string | nil
---@param filters {LegendaryItemFilter} | nil
function M.find(opts: LegendaryFindOpts, _deprecated: any)
  opts = opts or {}

  if type(opts) ~= 'table' or _deprecated ~= nil then
    opts = {}
    vim.notify("The API for `require('legendary').find()` has changed, please see https://github.com/mrjones2014/legendary.nvim#usage and update your usages.")
  end

  local item_kind = opts.kind or ''
  local current_mode = (vim.fn.mode() or '') as string
  local current_buf = vim.api.nvim_get_current_buf()
  local visual_selection: table = nil
  if utils.is_visual_mode(current_mode) then
    visual_selection = utils.get_marks()
    utils.send_escape_key()
  end
  local cursor_position = vim.api.nvim_win_get_cursor(0)
  local items: {LegendaryItem}
  if string.find(item_kind, 'keymap') then
    items = keymaps as {LegendaryItem}
  elseif string.find(item_kind, 'command') then
    items = commands as {LegendaryItem}
  elseif string.find(item_kind, 'autocmd') then
    items = autocmds as {LegendaryItem}
  elseif item_kind == 'legendary.function' then
    items = functions as {LegendaryItem}
  else
    items = vim.list_extend({}, keymaps as {LegendaryItem})
    items = vim.list_extend(items, commands as {LegendaryItem})
    items = vim.list_extend(items, autocmds as {LegendaryItem})
    items = vim.list_extend(items, functions as {LegendaryItem})
  end


  -- only search for last used item if kind matches
  if
    require('legendary.config').most_recent_item_at_top
    and last_used_item
    and type(item_kind) == 'string'
    and vim.startswith(last_used_item.kind, item_kind)
  then
    for i, item in ipairs(items) do
      if item.id == last_used_item.id then
        -- move to top of list
        table.remove(items, i)
        table.insert(items, 1, item)
        goto last_used_item_found
      end
    end

    ::last_used_item_found::
  end

  local filters = opts.filters or {}
  if type(filters) == 'function' then
    filters = { filters as LegendaryItemFilter }
  end

  -- buffer-specific items should only appear for the current buffer
  table.insert(filters, function(item: LegendaryItem): boolean
    return item.opts == nil or item.opts.buffer == nil or item.opts.buffer == current_buf
  end)

  for _, filter in ipairs(filters as {LegendaryItemFilter}) do
    if type(filter) ~= 'function' then
      utils.notify('Passed an item filter that is not a function', vim.log.levels.WARN)
      goto skip_filter
    end

    items = vim.tbl_filter(function(item: LegendaryItem): boolean
      local result = filter(item)
      if type(result) ~= 'boolean' then
        return true
      end

      return result
    end, items)

    ::skip_filter::
  end

  local select_kind = string.format(
    'legendary.%s',
    type(item_kind) == 'string' and #item_kind > 0 and item_kind or 'items'
  )
  local prompt = require('legendary.config').select_prompt
  if type(prompt) == 'function' then
    prompt = (prompt as function(kind: string): string)(select_kind)
  end

  local format_item = function(item: LegendaryItem): string
    return formatter.format(item, current_mode, opts.formatter)
  end

  vim.ui.select(items, {
    prompt = vim.trim((prompt as string | nil) or ''),
    kind = select_kind,
    format_item = format_item,
  }, function(selected: LegendaryItem)
    if not selected then
      return
    end

    -- we only need a shallow copy, we only need kind and id
    -- only bother making the copy if feature is enabled
    if require('legendary.config').most_recent_item_at_top then
      last_used_item = vim.tbl_extend('force', {}, selected) as LegendaryItem
    end

    -- vim.schedule so that the select UI closes before we do anything
    vim.schedule(function()
      require('legendary.executor').try_execute(
        selected,
        current_buf,
        visual_selection,
        current_mode,
        cursor_position
      )
    end)
  end)
end

return M
