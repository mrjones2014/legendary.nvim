---In order to support ordering items by most recent use,
---we need a stable sorting algorithm. This is one.
---Lua's built-in `table.sort` is an unstable sort algorithm.
---Based on MIT licensed code: https://gist.github.com/1bardesign/62b90260e47ea807864fc3cc8f880f8d

local M = {}

local function sort_setup(array, comp)
  local n = #array
  local trivial = false
  --trivial cases; empty or 1 element
  if n <= 1 then
    trivial = true
  else
    --default comp
    comp = comp or function(a, b)
      return a < b
    end
    --check comp
    if comp(array[1], array[1]) then
      error('invalid order function for sorting')
    end
  end
  --setup complete
  return trivial, n, comp
end

---Stable table sort algorithm.
function M.sort_stable() end

return M
