-- Modified from the MIT-licensed code
-- at https://gist.github.com/1bardesign/62b90260e47ea807864fc3cc8f880f8d

local M = {}

--tunable size for
local max_chunk_size = 24

local function insertion_sort_impl(array, first, last, less)
  for i = first + 1, last do
    local k = first
    local v = array[i]
    for j = i, first + 1, -1 do
      if less(v, array[j - 1]) then
        array[j] = array[j - 1]
      else
        k = j
        break
      end
    end
    array[k] = v
  end
end

local function merge(array, workspace, low, middle, high, less)
  local i, j, k
  i = 1
  -- copy first half of array to auxiliary array
  for j = low, middle do
    workspace[i] = array[j]
    i = i + 1
  end
  -- sieve through
  i = 1
  j = middle + 1
  k = low
  while true do
    if (k >= j) or (j > high) then
      break
    end
    if less(array[j], workspace[i]) then
      array[k] = array[j]
      j = j + 1
    else
      array[k] = workspace[i]
      i = i + 1
    end
    k = k + 1
  end
  -- copy back any remaining elements of first half
  for k = k, j - 1 do
    array[k] = workspace[i]
    i = i + 1
  end
end

local function merge_sort_impl(array, workspace, low, high, less)
  if high - low <= max_chunk_size then
    insertion_sort_impl(array, low, high, less)
  else
    local middle = math.floor((low + high) / 2)
    merge_sort_impl(array, workspace, low, middle, less)
    merge_sort_impl(array, workspace, middle + 1, high, less)
    merge(array, workspace, low, middle, high, less)
  end
end

--inline common setup stuff
local function sort_setup(array, less)
  local n = #array
  local trivial = false
  --trivial cases; empty or 1 element
  if n <= 1 then
    trivial = true
  else
    --default less
    less = less or function(a, b)
      return a < b
    end
    --check less
    if less(array[1], array[1]) then
      error('invalid order function for sorting')
    end
  end
  --setup complete
  return trivial, n, less
end

function M.mergesort(array, less)
  --setup
  local trivial, n, less = sort_setup(array, less)
  if not trivial then
    --temp storage
    local workspace = {}
    workspace[math.floor((n + 1) / 2)] = array[1]
    --dive in
    merge_sort_impl(array, workspace, 1, n, less)
  end
  return array
end

return M
