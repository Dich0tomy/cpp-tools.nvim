describe('array_equals', function()
	local iter = require('cpp-tools.lib.iter')

	it('Two same references to empty are equal', function()
		local empty = {}
		local a = empty
		local b = empty

		assert.is.truthy(iter.arrays_equal(a, b))
	end)

	it('Two different references to empty are equal', function()
		local a = {}
		local b = {}

		assert.is.truthy(iter.arrays_equal(a, b))
	end)

	it('Two same values are equal', function()
		local a = { 1, 2 }
		local b = { 1, 2 }

		assert.is.truthy(iter.arrays_equal(a, b))
	end)

	it('Two same values with different order are not equal', function()
		local a = { 1, 2 }
		local b = { 2, 1 }

		assert.is.falsy(iter.arrays_equal(a, b))
	end)

	it('Two same values with different values', function()
		local a = { '' }
		local b = { 1 }

		assert.is.falsy(iter.arrays_equal(a, b))
	end)
end)

describe('line_count', function()
	local iter = require('cpp-tools.lib.iter')

	it('Returns 1 for an empty string', function()
		assert.are.equal(iter.line_count(''), 1)
	end)

	it('Returns 1 for a non empty string with one line', function()
		assert.are.equal(iter.line_count('Hello there'), 1)
	end)

	it('Returns 1 for a string with a trailing newlien', function()
		assert.are.equal(iter.line_count('Foo\n'), 1)
	end)

	it('Returns 2 for a string with a trailing newline and content after it', function()
		assert.are.equal(iter.line_count('Foo\nBar'), 2)
	end)

	it('Returns X for a string with X lines (ignoring last newline)', function()
		local three_lined_string = [[
      first line
      second line
      third line]]

		assert.are.equal(iter.line_count(three_lined_string), 3)
	end)
end)

describe('lines', function()
	local iter = require('cpp-tools.lib.iter')

	it('Returns one empty line untouched', function()
		local empty_line = ''
		local lines = iter.lines(empty_line)

		assert.are.equal(#lines, 1)
		assert.are.equal(lines[1], empty_line)
	end)

	it('Returns one non empty line untouched', function()
		local empty_line = 'asdasdasdasdasd'
		local lines = iter.lines(empty_line)

		assert.are.equal(#lines, 1)
		assert.are.equal(lines[1], empty_line)
	end)

	it('Returns X lines for a string with X lines', function()
		local lines_arr = { 'line1', 'line2', 'line3' }
		local lines_str = vim.fn.join(lines_arr, '\n')

		assert.is.truthy(iter.arrays_equal(iter.lines(lines_str), lines_arr))
	end)
end)
