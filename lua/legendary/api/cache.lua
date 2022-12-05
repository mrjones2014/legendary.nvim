local class = require('legendary.vendor.middleclass')
local Config = require('legendary.config')

local function create_cache_dir()
  local dir = Config.cache_path
  if vim.fn.isdirectory(dir) == 0 then
    vim.fn.mkdir(dir, 'p')
  end
end

---@class Cache
---@field new fun(self, filename:string):Cache
local Cache = class('Cache')

function Cache:initialize(filename)
  self.filename = filename
end

---Return the full filepath to the cache file
---@return string
function Cache:filepath()
  return vim.fn.simplify(string.format('%s/%s', Config.cache_path, self.filename))
end

---Write the cache file
---@param contents string|string[]
function Cache:write(contents)
  create_cache_dir()
  local filepath = self:filepath()
  local file = io.open(filepath, 'w+')
  if not file then
    vim.api.nvim_err_writeln(string.format('Failed to write file %s', filepath))
    return
  end

  local line_ending = vim.fn.has('win32') == 1 and '\r\n' or '\n'
  local contents_str = type(contents) == 'table' and table.concat(contents, line_ending) or contents
  file:write(contents_str --[[@as string]])
  file:close()
end

---Append a single line to a file
---@param line string
function Cache:append(line)
  create_cache_dir()
  local filepath = self:filepath()
  local file = io.open(filepath, 'a')
  if file == nil then
    vim.api.nvim_err_writeln(string.format('Failed to write file %s', filepath))
    return
  end
  file:write(string.format('%s\n', line))
  file:close()
end

---Read the cache file contents
---@return string[]
function Cache:read()
  local filepath = self:filepath()
  if vim.fn.filereadable(filepath) == 0 then
    return {}
  end

  local lines = {}
  for line in io.lines(filepath) do
    table.insert(lines, line)
  end

  return lines
end

return Cache
