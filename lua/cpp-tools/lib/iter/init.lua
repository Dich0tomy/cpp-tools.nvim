local M = {}

-- TODO: Use an iter mechanism instead of relying on tables everywhere

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

-- TODO: Instead of using an overengineered map thingy
-- have a more robust vim.iter mechanism

---Maps a range using a function, index or a name of an internal field
---Using a function will map the current element using the function,
---Using a field name will do `vim.tbl_get(t, name)`
---Using an integer will do `t[idx]`
---e.g. `fp.map({ { foo = 1 } }, 1, 'foo', function(x) return x * 2 end)` will return { 2 }
---@generic T, U
---@param range [`T`] The range to partition
---@param ... integer|string|fun(T): U Mapping functions or field names
---@return [U]|[any]
function M.map(range, ...)
	local mappings = { ... }
	return vim
		.iter(range)
		:map(function(t)
			return vim.iter(mappings):fold(t, function(final, mapping)
				local mapping_type = type(mapping)
				if mapping_type == 'string' then
					assert(
						type(t) == 'table',
						('The type of element must be a table to use a field name mapping (type type is [%s])'):format(type(t))
					)

					return vim.tbl_get(final, mapping)
				elseif mapping_type == 'number' then
					return final[mapping]
				elseif mapping_type == 'function' then
					return mapping(final)
				else
					assert(
						false,
						('The type of mapping must be a function, a string or an integer, not [%s]'):format(mapping_type)
					)
				end
			end)
		end)
		:totable()
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

	describe('`map()`', function()
		it('Maps using a function', function()
			local arr = { 1, 2, 3, 4 }
			local mapped = M.map(arr, function(n)
				return n * 2
			end)

			assert.are.same(mapped, { 2, 4, 6, 8 })
		end)
		it('Maps using chained functions', function()
			local arr = { 1, 2, 3, 4 }
			local mapped = M.map(
				arr,
				function(n)
					return n * 2
				end, -- 2 4 6 8
				function(n)
					return n - 1
				end -- 1 3 5 7
			)

			assert.are.same(mapped, { 1, 3, 5, 7 })
		end)

		it('Maps using a single field name', function()
			local arr = {
				{ foo = 1, bar = 2 },
				{ foo = 1, bar = 2 },
				{ foo = 1, bar = 2 },
			}
			local foos = M.map(arr, 'foo')
			local bars = M.map(arr, 'bar')

			assert.are.same(foos, { 1, 1, 1 })
			assert.are.same(bars, { 2, 2, 2 })
		end)

		it('Maps nested tables', function()
			local arr = {
				{ foo = { bar = 1, qoox = { foox = 2, boox = 5 } } },
				{ foo = { bar = 2, qoox = { foox = 1, boox = 4 } } },
			}
			local bars = M.map(arr, 'foo', 'bar')
			local fooxes = M.map(arr, 'foo', 'qoox', 'foox')

			assert.are.same(bars, { 1, 2 })
			assert.are.same(fooxes, { 2, 1 })
		end)

		it('Maps with both functions and field names tables', function()
			local arr = {
				{ foo = { bar = 1, qoox = { foox = 2, boox = 5 } } },
				{ foo = { bar = 2, qoox = { foox = 2, boox = 5 } } },
			}
			local bars = M.map(arr, 'foo', 'bar', function(e)
				return e * 2
			end)

			assert.are.same(bars, { 2, 4 })
		end)

		it('Maps using index', function()
			local arr1 = {
				{ { foo = 1, bar = 2 } },
				{ { foo = 1, bar = 2 } },
			}
			local arr2 = {
				{ foo = { 1, 2 } },
				{ foo = { 1, 2 } },
			}
			local arr3 = {
				{ { { { 'foo' } } } },
			}

			local mapped1 = M.map(arr1, 1, 'foo')
			local mapped2 = M.map(arr2, 'foo', 2)
			local mapped3 = M.map(arr3, 1, 1, 1, 1, function(s)
				return ('%sbar'):format(s)
			end)

			assert.are.same(mapped1, { 1, 1 })
			assert.are.same(mapped2, { 2, 2 })
			assert.are.same(mapped3, { 'foobar' })
		end)
	end)
end

return M
