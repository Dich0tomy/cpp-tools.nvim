local M = {}

--------------------------------------------------
-- Types
--------------------------------------------------

---@alias cpp-tools.paths.Requirable string
---@alias cpp-tools.paths.Path string

---@class cpp-tools.paths.BulkRequireResult
---@field path cpp-tools.paths.Path The path for which fun was called
---@field result any The result of fun(path)

--------------------------------------------------
-- Types
--------------------------------------------------

local function bulk_require_impl(path, fs_dir_opts, fun)
	return vim
		.iter(vim.fs.dir(path, fs_dir_opts))
		:filter(function(_name, type)
			return type == 'file'
		end)
		:map(function(file)
			return ('%s/%s'):format(path, file)
		end)
		:map(function(path)
			return {
				path = path,
				result = { fun(path) },
			}
		end)
		:totable()
end

---Returns an absolute path of the calling script
---@return string # The path
function M.current_path()
	return debug.getinfo(2).source:sub(2)
end

---Returns an absolute dir of the calling script
---@return string # The path
function M.current_dir()
	return vim.fs.dirname(debug.getinfo(2).source:sub(2))
end

---Returns the filename of the calling script
---@return string # The filename
function M.current_filename()
	--[=[
	 NOTE: This *cannot* be refactored into
	 ```lua
	 return- M.current_path():match(...)
	 ```
	 Because `debug.getinfo` returns debug info from the standpoint of
	 a given function level. When calling `getinfo(2)` from some other script,
	 we go 2 levels up - to the calling file,
	 but if we called this and then in turn call `getinfo(2)`, we would go 2 levels up - to this function
	]=]
	return debug.getinfo(2).source:match('([%w_%.]+)$')
end

---Tries to iterate over a directory and pcall(dofile) each file in there
---
---@param path cpp-tools.paths.Path The path to all the modules
---@param fs_dir_opts table<string, any>? The opts to pass to `vim.fs.dir`
---@return cpp-tools.paths.BulkRequireResult[]
function M.try_bulk_require(path, fs_dir_opts)
	return bulk_require_impl(path, fs_dir_opts, function(p)
		return pcall(dofile, p)
	end)
end

---Iterates over a directory and dofile's each file in there
---
---@param path cpp-tools.paths.Path The path to all the modules
---@param fs_dir_opts table<string, any>? The opts to pass to `vim.fs.dir`
---@return cpp-tools.paths.BulkRequireResult[]
function M.bulk_require(path, fs_dir_opts)
	return bulk_require_impl(path, fs_dir_opts, dofile)
end

---@package
function M.__test(testfiles)
	describe('`try_bulk_require()`', function()
		it('properly requires good, flat modules', function()
			local test_files = testfiles .. '/lib/paths/try_bulk_require/good/flat'

			local mods = M.try_bulk_require(test_files)

			assert.are.no.equal(#mods, 0)

			for _, result in ipairs(mods) do
				assert.message(('%s - %s'):format(result.path, result.result[2])).is.truthy(result.result[1])
			end
		end)

		it('properly requires good, nested modules', function()
			local test_files = testfiles .. '/lib/paths/try_bulk_require/good/nested'

			local mods = M.try_bulk_require(test_files, { depth = 3 })

			assert.are.no.equal(#mods, 0)

			for _, result in ipairs(mods) do
				assert.message(('%s - %s'):format(result.path, result.result[2])).is.truthy(result.result[1])
			end
		end)

		it('properly requires bad, flat modules', function()
			local test_files = testfiles .. '/lib/paths/try_bulk_require/bad/flat'

			local mods = M.try_bulk_require(test_files)

			assert.are.no.equal(#mods, 0)

			for _, result in ipairs(mods) do
				assert.message(('%s - %s'):format(result.path, result.result[2])).is.falsy(result.result[1])
			end
		end)

		it('properly requires bad, nested modules', function()
			local test_files = testfiles .. '/lib/paths/try_bulk_require/bad/nested'

			local mods = M.try_bulk_require(test_files, { depth = 3 })

			assert.are.no.equal(#mods, 0)

			for _, result in ipairs(mods) do
				assert.message(('%s - %s'):format(result.path, result.result[2])).is.falsy(result.result[1])
			end
		end)
	end)
end

return M
