local M = {}

---Return a function with statically set arguments.
---@param fn function The function to execute lazily
---@param ... any The arguments to pass to `fn` when called
---@return function
function M.lazy(fn, ...)
  local args = { ... }
  return function()
    fn(unpack(args))
  end
end

local function is_function(a)
  if type(a) == 'function' then
    return true
  end

  local mt = getmetatable(a)
  if not mt then
    return false
  end

  return not not mt.__call
end

---Return a function which lazily `require`s a module and
---calls a function from it. Functions nested within tables
---may be accessed using dot-notation, i.e.
---`lazy_required_fn('module_name', 'some.nested.fn', some_argument)`
---@param module_name string The module to `require`
---@param fn_name string The table path to the function
---@param ... any The arguments to pass to the function
---@return function
function M.lazy_required_fn(module_name, fn_name, ...)
  local args = { ... }
  return function()
    local module = (_G['require'](module_name))
    if string.find(fn_name, '%.') then
      local fn = module
      for _, key in ipairs(vim.split(fn_name, '%.', { trimempty = true })) do
        fn = (fn)[key]
        if fn == nil then
          vim.notify('[legendary.nvim]: invalid lazy_required_fn usage: no such function path')
          return
        end
      end
      if not is_function(fn) then
        vim.notify('[legendary.nvim]: invalid lazy_required_fn usage: no such function path')
        return
      end
      local final_fn = fn
      final_fn(unpack(args))
    else
      local fn = module[fn_name]
      fn(unpack(args))
    end
  end
end

---Return a function that creates a new horizontal
---split, then calls the given function.
---@param fn function The function to call after creating a split
---@return function
function M.split_then(fn)
  return function()
    vim.cmd('sp')
    fn()
  end
end

---Return a function that creates a new vertical
---split, then calls the given function.
---@param fn function The function to call after creating a split
---@return function
function M.vsplit_then(fn)
  return function()
    vim.cmd('vsp')
    fn()
  end
end

---Check if an item is a Keymap
---@param keymap LegendaryItem
---@return boolean
function M.is_keymap(keymap)
  -- inline require to avoid circular dependency
  return keymap.class == require('legendary.data.keymap')
end

---Check if an item is a Command
---@param cmd LegendaryItem
---@return boolean
function M.is_command(cmd)
  -- inline require to avoid circular dependency
  return cmd.class == require('legendary.data.command')
end

---Check if an item is an Augroup
---@param au LegendaryItem
---@return boolean
function M.is_augroup(au)
  -- inline require to avoid circular dependency
  return au.class == require('legendary.data.augroup')
end

---Check if an item is an Autocmd
---@param autocmd LegendaryItem
---@return boolean
function M.is_autocmd(autocmd)
  -- inline require to avoid circular dependency
  return autocmd.class == require('legendary.data.autocmd')
end

---Check if an item is an Augroup or Autocmd
---@param au_or_autocmd LegendaryItem
---@return boolean
function M.is_augroup_or_autocmd(au_or_autocmd)
  -- inline require to avoid circular dependency
  return au_or_autocmd.class == require('legendary.data.augroup')
    or au_or_autocmd.class == require('legendary.data.autocmd')
end

---Check if an item is a Function
---@param func LegendaryItem
---@return boolean
function M.is_function(func)
  -- inline require to avoid circular dependency
  return func.class == require('legendary.data.function')
end

---Check if the given mode string indicates a visual mode or a sub-mode of visual mode.
---Defaults to `vim.fn.mode()`
---@param mode_str string|nil
---@return boolean
---@overload fun()
function M.is_visual_mode(mode_str)
  mode_str = mode_str or vim.fn.mode()
  if mode_str == 'nov' or mode_str == 'noV' or mode_str == 'no' then
    return false
  end

  return not not (string.find(mode_str:lower(), 'v') or string.find(mode_str:lower(), '') or mode_str == 'x')
end

---@class Marks
---@field [1] integer
---@field [2] integer
---@field [3] integer
---@field [4] integer

---Get visual marks in format {start_line, start_col, end_line, end_col}
---@return Marks
function M.get_marks()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local cline, ccol = cursor[1], cursor[2]
  local vline, vcol = vim.fn.line('v'), vim.fn.col('v')
  if ccol > vcol then
    local swap = vcol
    vcol = ccol + 1
    ccol = swap
  end
  return { cline, ccol, vline, vcol }
end

---Set visual marks from a table in the format
---{start_line, start_col, end_line, end_col}
---@param marks Marks the marks to set
function M.set_marks(marks)
  vim.fn.setpos("'<", { 0, marks[1], marks[2], 0 })
  vim.fn.setpos("'>", { 0, marks[3], marks[4], 0 })
end

---Parse a vimscript mapping command (e.g. `vnoremap <silent> <leader>f :SomeCommand<CR>`)
---and return a `legendary.nvim` keymapping table that can be used in your configuration.
---@param vimscript_str string
---@param description string
---@return table
function M.table_from_vimscript(vimscript_str, description)
  local _, input = require('legendary.data.keymap'):from_vimscript(vimscript_str, description)
  return input
end

return M
