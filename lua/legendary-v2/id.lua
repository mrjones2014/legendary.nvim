local M = {}

-- incremented before first returned,
-- so first ID will be 0
local next_id = -1

---Get a unique ID
---@return integer
function M.new()
  next_id = next_id + 1
  return next_id + 0 -- adding 0 makes a copy
end

return M
