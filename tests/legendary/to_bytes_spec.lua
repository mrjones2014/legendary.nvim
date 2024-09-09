local assert = require('luassert')
local wrapper = require('legendary.api.db.wrapper')

describe('to_bytes function', function()
  local test_data = {
    ['test string'] = '11610111511632115116114105110103',
    ['with icons 󰊢'] = '119105116104321059911111011532243176138162238158168238153135',
    ['with quote chars \'"'] = '11910511610432113117111116101329910497114115323934',
    ['with emoji 🦀'] = '1191051161043210110911110610532240159166128',
  }
  for input, output in pairs(test_data) do
    it(string.format('for input `%s`, output should be "%s"', input, output), function()
      assert.are.same(wrapper.to_bytes(input), output)
    end)
  end
end)
