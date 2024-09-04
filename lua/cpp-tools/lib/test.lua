---This file contains useful functions for usage inside tests.
---They're here, because they are not necessarily generic and are more of the "debug" functions kind.
local M = {}

---Returns the root of the project
---@return string
function M.root()
	return vim.fs.root(0, 'testfiles') --[[@as string]]
end

return M
