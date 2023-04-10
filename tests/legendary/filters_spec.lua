local assert = require('luassert')
local filters = require('legendary.filters')

describe('legendary.filters', function()
  describe('AND', function()
    it('should return false when ANY item returns false', function()
      local input = {
        function()
          return true
        end,
        function()
          return true
        end,
        function()
          return false
        end,
      }
      local anded = filters.AND(unpack(input))
      assert.False(anded({}, {}))
    end)

    it('should return true when ALL items return true', function()
      local input = {
        function()
          return true
        end,
        function()
          return true
        end,
        function()
          return true
        end,
      }
      local anded = filters.AND(unpack(input))
      assert.True(anded({}, {}))
    end)
  end)

  describe('OR', function()
    it('should return true when ANY items return true', function()
      local input = {
        function()
          return true
        end,
        function()
          return false
        end,
        function()
          return false
        end,
      }
      local ored = filters.OR(unpack(input))
      assert.True(ored({}, {}))
    end)

    it('should return false when ALL items return false', function()
      local input = {
        function()
          return false
        end,
        function()
          return false
        end,
        function()
          return false
        end,
      }
      local ored = filters.OR(unpack(input))
      assert.False(ored({}, {}))
    end)
  end)
end)
