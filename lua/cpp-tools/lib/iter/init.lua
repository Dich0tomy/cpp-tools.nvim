local M = {}

---Counts the lines in a string
---@param str string the string to count lines for
---@return number line count # The number of lines
function M.line_count(str)
	local count = 1
	local length = #str
	for i = 1, length - 1 do
		local c = str:sub(i, i)
		if c == '\n' then
			if i ~= (length - 2) then
				count = count + 1
			end
		end
	end

	return count
end

---Splits the string into lines and immediately returns the amount as well
---@param str string the string to split
---@return string[] lines # An array of lines
---@return number # The amount of lines in the array
function M.lines(str)
	local lines = vim.split(str, '\n')
	return lines, #lines
end

---Checks if two array tables have equal values
---@generic T
---@param arr1 `T`[] first array
---@param arr2 T[] second array
---@return boolean # are the arrays equal
function M.arrays_equal(arr1, arr2)
	if arr1 == arr2 then
		return true
	elseif #arr1 ~= #arr2 then
		return false
	end

	for i = 1, #arr1 do
		if arr1[i] ~= arr2[i] then
			return false
		end
	end

	return true
end

function M.__test()
	describe('`array_equals()`', function()
		it('Two same references to empty are equal', function()
			local empty = {}
			local a = empty
			local b = empty

			assert.is.truthy(M.arrays_equal(a, b))
		end)

		it('Two different references to empty are equal', function()
			local a = {}
			local b = {}

			assert.is.truthy(M.arrays_equal(a, b))
		end)

		it('Two same values are equal', function()
			local a = { 1, 2 }
			local b = { 1, 2 }

			assert.is.truthy(M.arrays_equal(a, b))
		end)

		it('Two same values with different order are not equal', function()
			local a = { 1, 2 }
			local b = { 2, 1 }

			assert.is.falsy(M.arrays_equal(a, b))
		end)

		it('Two same values with different values', function()
			local a = { '' }
			local b = { 1 }

			assert.is.falsy(M.arrays_equal(a, b))
		end)
	end)

	describe('`line_count()`', function()
		it('Returns 1 for an empty string', function()
			assert.are.equal(M.line_count(''), 1)
		end)

		it('Returns 1 for a non empty string with one line', function()
			assert.are.equal(M.line_count('Hello there'), 1)
		end)

		it('Returns 1 for a string with a trailing newlien', function()
			assert.are.equal(M.line_count('Foo\n'), 1)
		end)

		it('Returns 2 for a string with a trailing newline and content after it', function()
			assert.are.equal(M.line_count('Foo\nBar'), 2)
		end)

		it('Returns X for a string with X lines (ignoring last newline)', function()
			local three_lined_string = [[
			first line
			second line
			third line]]

			assert.are.equal(M.line_count(three_lined_string), 3)
		end)
	end)

	describe('`lines()`', function()
		it('Returns one empty line untouched', function()
			local empty_line = ''
			local lines = M.lines(empty_line)

			assert.are.equal(#lines, 1)
			assert.are.equal(lines[1], empty_line)
		end)

		it('Returns one non empty line untouched', function()
			local empty_line = 'asdasdasdasdasd'
			local lines = M.lines(empty_line)

			assert.are.equal(#lines, 1)
			assert.are.equal(lines[1], empty_line)
		end)

		it('Returns X lines for a string with X lines', function()
			local lines_arr = { 'line1', 'line2', 'line3' }
			local lines_str = vim.fn.join(lines_arr, '\n')

			assert.is.truthy(M.arrays_equal(M.lines(lines_str), lines_arr))
		end)
	end)
end

return M
