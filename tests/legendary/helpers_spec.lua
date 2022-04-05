local assert = require('luassert')
local helpers = require('legendary.helpers')

describe('legendary.helpers', function()
  describe('unpack(...)', function()
    it('unpacks arguments', function()
      local args = { 1, 2, 3 }
      local result1, result2, result3 = helpers.unpack(args)
      assert.are.same(result1, 1)
      assert.are.same(result2, 2)
      assert.are.same(result3, 3)
    end)
  end)

  describe('lazy(fn, ...)', function()
    it('returns a new function, does not execute the function immediately', function()
      local lazy_fn_executed = false
      local lazy_fn = function(value)
        lazy_fn_executed = value
      end
      local result = helpers.lazy(lazy_fn, true)
      assert.is_not.True(lazy_fn_executed)
      result()
      assert.True(lazy_fn_executed)
    end)

    it('properly forwards all arguments', function()
      local lazy_fn_values = {}
      local lazy_fn = function(arg1, arg2, arg3)
        table.insert(lazy_fn_values, arg1)
        table.insert(lazy_fn_values, arg2)
        table.insert(lazy_fn_values, arg3)
      end
      local lazy_fn_result = helpers.lazy(lazy_fn, 1, 2, 3)
      assert.are.same(#lazy_fn_values, 0)
      lazy_fn_result()
      assert.are.same(#lazy_fn_values, 3)
      assert.are.same(lazy_fn_values[1], 1)
      assert.are.same(lazy_fn_values[2], 2)
      assert.are.same(lazy_fn_values[3], 3)
    end)
  end)

  describe('lazy_required_fn', function()
    it('returns a new function that calls the module function, does not execute immediately', function()
      local module_fn_executed = false
      package.loaded['_test-module'] = {
        test_fn = function()
          module_fn_executed = true
        end,
      }
      local result = helpers.lazy_required_fn('_test-module', 'test_fn')
      assert.is_not.True(module_fn_executed)
      result()
      assert.True(module_fn_executed)
    end)

    it('forwards all args to the required module function', function()
      local lazy_fn_values = {}
      package.loaded['_test-module'] = {
        test_fn = function(arg1, arg2, arg3)
          table.insert(lazy_fn_values, arg1)
          table.insert(lazy_fn_values, arg2)
          table.insert(lazy_fn_values, arg3)
        end,
      }
      local result = helpers.lazy_required_fn('_test-module', 'test_fn', 1, 2, 3)
      assert.are.same(#lazy_fn_values, 0)
      result()
      assert.are.same(#lazy_fn_values, 3)
      assert.are.same(lazy_fn_values[1], 1)
      assert.are.same(lazy_fn_values[2], 2)
      assert.are.same(lazy_fn_values[3], 3)
    end)
  end)
end)
