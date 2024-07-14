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
      if (i ~= (length - 2)) then
        count = count + 1
      end
    end
	end

	return count
end

---Splits the string into lines
---@param str string the string to split
---@return string[] lines # An array of lines
function M.lines(str)
	return vim.split(str, '\n')
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

return M
