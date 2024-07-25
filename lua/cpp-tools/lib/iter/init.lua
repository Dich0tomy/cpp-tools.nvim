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

---Partitions the given range into one satisfying the pred and one not satisfying the pred
---@generic T
---@param range [`T`] The range to partition
---@param pred fun(T): boolean The predicate by which to partition
---@return [T] # [T] satisfying the predicate
---@return [T] # [T] not satisfying the predicate
function M.partition(range, pred, proj_beg)
	local fp = require('cpp-tools.lib.fp')
	proj_beg = fp.maybe_fn(proj_beg)

	return vim.iter(range):map(proj_beg):filter(pred):totable() or {},
		vim.iter(range):map(proj_beg):filter(fp.nah(pred)):totable() or {}
end

---@package
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

	describe('`partition()`', function()
		it('Partitions all left', function()
			local arr = { 1, 2, 3, 4, 5, 6, 7, 8 }
			local good, bad = M.partition(arr, function()
				return true
			end)

			assert.are.same(good, arr)
			assert.are.same(bad, {})
		end)

		it('Partitions all right', function()
			local arr = { 1, 2, 3, 4, 5, 6, 7, 8 }
			local good, bad = M.partition(arr, function()
				return false
			end)

			assert.are.same(good, {})
			assert.are.same(bad, arr)
		end)

		it('Partitions both sides', function()
			local arr = { 1, 2, 3, 4, 5, 6, 7, 8 }
			local good, bad = M.partition(arr, function(n)
				return n % 2 == 0
			end)

			assert.are.same(good, { 2, 4, 6, 8 })
			assert.are.same(bad, { 1, 3, 5, 7 })
		end)

		it('Applies the projection properly', function()
			local arr = { 1, 2, 3, 4, 5, 6, 7, 8 }
			local good, bad = M.partition(arr, function(n)
				return n < 10
			end, function(n)
				return n * 2
			end)

			assert.are.same(good, { 2, 4, 6, 8 })
			assert.are.same(bad, { 10, 12, 14, 16 })
		end)
	end)
end

return M
