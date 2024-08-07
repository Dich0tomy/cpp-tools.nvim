--- For some reason when I define the tests in the main runner the busted context cannot be found,
--- so I just created another file for that.

local M = {}

---@package
function M.__test(testfiles_dir)
	describe('auto test runner', function()
		it('returns a proper testfiles dir', function()
			local file = testfiles_dir .. '/auto_test_runner/test.txt'
			print(file)
			local f, msg = io.open(file)

			if not f then
				assert.message(('Kurwa nie dziala: %s'):format(msg)).falsy(true)
			end

			assert.are.equal(vim.trim(f:read('*a')), 'works')
		end)
	end)
end

return M
