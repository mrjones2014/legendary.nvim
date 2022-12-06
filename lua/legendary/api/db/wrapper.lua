-- Some code in this file is modified from the MIT licensed code at
-- https://github.com/nvim-telescope/telescope-frecency.nvim

local ok, sqlite = pcall(require, 'sqlite')
if not ok then
  error('Frecency sorting requires sqlite.lua (https://github.com/tami5/sqlite.lua) ' .. tostring(sqlite))
  return
end

local Config = require('legendary.config')
local Log = require('legendary.log')

local db_name = 'legendary_frecency.sqlite3'

---@class legendaryDbTables
---@field item_count string
---@field timestamps string
local db_tables = {
  item_count = 'item_count',
  timestamps = 'timestamps',
}

local cmd = {
  select = 1,
  insert = 2,
  delete = 3,
  eval = 4,
}

---@class DbWrapper
local M = {}

---@return DbWrapper
function M:new()
  local wrapper = {}
  setmetatable(wrapper, self)
  self.__index = self
  self.db = nil
  return wrapper
end

function M.delete_db()
  local db_path = string.format('%s%s', Config.sort.frecency.db_root, db_name)
  if vim.fn.filereadable(db_path) == 1 then
    vim.fn.delete(db_path)
  end
end

function M:bootstrap()
  if self.db then
    return
  end

  Log.trace('Initializing frecency database...')

  if vim.fn.isdirectory(Config.sort.frecency.db_root) == 0 then
    vim.fn.mkdir(Config.sort.frecency.db_root, 'p')
  end

  local db_path = string.format('%s%s', Config.sort.frecency.db_root, db_name)
  local db_ok, db_opened = pcall(function()
    return sqlite:open(db_path)
  end)
  if not db_ok then
    Log.error('Failed to open database at %s: %s', db_path, db_opened)
    return
  else
    self.db = db_opened
  end

  local first_run = false
  if not self.db:exists(db_tables.item_count) then
    first_run = true
    self.db:create(db_tables.item_count, {
      id = { 'INTEGER', 'PRIMARY', 'KEY' },
      item_id = { 'TEXT' },
      count = { 'INTEGER' },
    })
    self.db:create(db_tables.timestamps, {
      id = { 'INTEGER', 'PRIMARY', 'KEY' },
      item_id = { 'TEXT' },
      timestamp = { 'REAL' },
    })
  end

  self.db:close()
  Log.trace('Frecency database initialized.')
  return first_run
end

function M:transaction(t, params)
  Log.trace('Performing SQL transaction with following data: %s', vim.inspect({ query = t, params = params }))
  return self.db:with_open(function(db)
    local case = {
      [cmd.select] = function()
        return db:select(t.cmd_data, params)
      end,
      [cmd.insert] = function()
        return db:insert(t.cmd_data, params)
      end,
      [cmd.delete] = function()
        return db.delete(t.cmd_data, params)
      end,
      [cmd.eval] = function()
        return db:eval(t.cmd_data, params)
      end,
    }
    return case[t.cmd]()
  end)
end

M.queries = {
  item_add_entry = {
    cmd = cmd.insert,
    cmd_data = db_tables.item_count,
  },
  item_delete_entry = {
    cmd = cmd.delete,
    cmd_data = db_tables.item_count,
  },
  item_get_entries = {
    cmd = cmd.select,
    cmd_data = db_tables.item_count,
  },
  item_update_counter = {
    cmd = cmd.eval,
    cmd_data = 'UPDATE item_count SET count = count + 1 WHERE item_id == :item_id;',
  },
  timestamp_add_entry = {
    cmd = cmd.eval,
    cmd_data = "INSERT INTO timestamps (item_id, timestamp) values(:item_id, julianday('now'));",
  },
  timestamp_delete_entry = {
    cmd = cmd.delete,
    cmd_data = db_tables.timestamps,
  },
  timestamp_get_all_entries = {
    cmd = cmd.select,
    cmd_data = db_tables.timestamps,
  },
  timestamp_get_all_entry_ages = {
    cmd = cmd.eval,
    cmd_data = "SELECT id, item_id, CAST((julianday('now') - julianday(timestamp)) * 24 * 60 AS INTEGER) AS age FROM timestamps;", -- luacheck: no max line length
  },
  timestamp_delete_before_id = {
    cmd = cmd.eval,
    cmd_data = 'DELETE FROM timestamps WHERE id < :id and item_id == :item_id;',
  },
}

local function row_id(row)
  return (not vim.tbl_isempty(row)) and row[1].id or nil
end

function M.sql_escape(str)
  return string.format("'%s'", string.gsub(str, "'", "\\'"))
end

---Update the stored data for an item
---@param item LegendaryItem
function M:update(item)
  local item_id = M.sql_escape(item:id())
  Log.trace('Updating item with ID "%s"', item_id)
  local entry_id = row_id(self:transaction(self.queries.item_get_entries, { where = { item_id = item_id } }))
  if not entry_id then
    self:transaction(self.queries.item_add_entry, { item_id = item_id, count = 1 })
  end

  -- create timestamp entry for this update
  self:transaction(self.queries.timestamp_add_entry, { item_id = item_id })

  -- trim timestamps table to Config.sort.frecency.max_timestamps
  local timestamps = self:transaction(self.queries.timestamp_get_all_entries, { where = { item_id = item_id } })
  local trim_at = timestamps[(#timestamps - Config.sort.frecency.max_timestamps) + 1]
  if trim_at then
    self:transaction(self.queries.timestamp_delete_before_id, { id = trim_at.id, item_id = item_id })
  end
end

return M
