local function buftype_filter(value)
  return function(_, context)
    if type(value) == 'string' then
      return context.buftype == value
    else
      for _, value_inner in ipairs(value) do
        if context.buftype ~= value_inner then
          return false
        end
      end
      return true
    end
  end
end

local function filetype_filter(value)
  return function(_, context)
    if type(value) == 'string' then
      return context.filetype == value
    else
      for _, value_inner in ipairs(value) do
        if context.filetype ~= value_inner then
          return false
        end
      end
      return true
    end
  end
end

---A middleclass class mixin to parse filters
local M = {}

---Take the filters input and return a list of filter functions
---Also sets self.filters to the result
---@param filters table
---@return (function[])|nil
function M.parse_filters(self, filters)
  if not filters then
    return nil
  end

  local result = {}

  for key, value in pairs(filters) do
    -- check special keys
    if key == 'buftype' or key == 'bt' then
      table.insert(result, buftype_filter(value))
    end
    if key == 'filetype' or key == 'ft' then
      table.insert(result, filetype_filter(value))
    end

    -- then list items
    if type(key) == 'number' and type(value) == 'function' then
      table.insert(result, value)
    end
  end

  self.filters = result
  return result
end

return M
