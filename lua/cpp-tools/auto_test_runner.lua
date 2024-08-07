--- This is a special file which gets called by busted.
--- This file scans all the requirable `lua/` files from here
--- and runs their __test functions with busted test context.

local current_filename = debug.getinfo(1).source:match('([%w_%.]+)$')
local testfiles_dir = vim.fs.root(0, 'testfiles')

local function project_lua_files(path, type)
	return type == 'file' and vim.endswith(path, 'lua') and not vim.endswith(path, current_filename)
end

local function run_module_test(name)
	local ok, module = pcall(dofile, name)
	if not ok then
		describe(name, function()
			it('Has an error!', function()
				assert.message(('Requiring this module failed with the following error:\n%s'):format(module)).truthy(false)
			end)
		end)
		return
	end

	-- This module is something else, we don't fw it
	if type(module) ~= 'table' then
		return
	end

	local test_func = vim.tbl_get(module, '__test')
	if test_func then
		setfenv(test_func, getfenv())(testfiles_dir)
	end
end

local function is_lua_dir(dir)
	return vim.startswith(dir, 'lua')
end

vim.iter(vim.fs.dir('.', { depth = 10, skip = is_lua_dir })):filter(project_lua_files):each(run_module_test)
