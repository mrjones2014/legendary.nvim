-- Some code in this file is modified from the MIT licensed code at
-- https://github.com/nvim-telescope/telescope-frecency.nvim

local DbWrapper = require('legendary.api.db.wrapper')
local Config = require('legendary.config')

-- modifier used as a weight in the recency_score calculation:
local recency_modifier = {
  [1] = { age = 240, value = 100 }, -- past 4 hours
  [2] = { age = 1440, value = 80 }, -- past day
  [3] = { age = 4320, value = 60 }, -- past 3 days
  [4] = { age = 10080, value = 40 }, -- past week
  [5] = { age = 43200, value = 20 }, -- past month
  [6] = { age = 129600, value = 10 }, -- past 90 days
}

local function item_score(frequency, timestamps)
  local recency_score = 0
  for _, ts in pairs(timestamps) do
    for _, rank in ipairs(recency_modifier) do
      if ts.age <= rank.age then
        recency_score = recency_score + rank.value
        break
      end
    end
  end

  return frequency * recency_score / Config.sort.frecency.max_timestamps
end

local function filter_timestamps(timestamps, item_id)
  local res = {}
  for _, entry in pairs(timestamps) do
    if entry.item_id == item_id then
      table.insert(res, entry)
    end
  end
  return res
end

---@class LegendaryDbClient
local M = {}

M.db_wrapper = nil

---@return LegendaryDbClient
function M.init()
  if M.db_wrapper then
    return M
  end

  M.db_wrapper = DbWrapper:new()
  M.db_wrapper:bootstrap()
  return M
end

function M.get_item_scores()
  if not M.db_wrapper then
    return {}
  end

  local item_entries = M.db_wrapper:transaction(M.db_wrapper.queries.item_get_entries, {})
  local timestamp_ages = M.db_wrapper:transaction(M.db_wrapper.queries.timestamp_get_all_entry_ages, {})
  local scores = {}
  if #item_entries == 0 then
    return scores
  end

  for _, item_entry in ipairs(item_entries) do
    local score = item_entry.count == 0 and 0
      or item_score(item_entry.count, filter_timestamps(timestamp_ages, item_entry.item_id))
    scores[item_entry.item_id] = score
  end

  return scores
end

function M.update_item_score(item)
  M.db_wrapper:update(item)
end

function M.sql_escape(str)
  return M.db_wrapper.sql_escape(str)
end

return M
