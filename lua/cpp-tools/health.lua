-- Inspired by mrcjkb/haskell-tools.nvim
local h = vim.health
local start = h.start
local ok = h.ok
local error = h.error
local warn = h.warn

local function dep_exists(name)
	return vim.loader.find(name)
end

local function validate_config()
	start('Checking config')
end

local function ensure_system_dependencies()
	start('Checking system dependencies')
end

local function ensure_lua_dependencies()
	start('Checking lua dependencies')
end

local function ensure_dependencies()
	start('Checking dependencies')
	local deps = {
		'lspconfig',
	}

	vim
		.iter(deps)
		:map(function(dep)
			return { dep, dep_exists(dep) }
		end)
		:filter(function(dep)
			return dep[1] == false
		end)
		:each(function(not_found_dep) end)
end

local M = {}

function M.check()
	validate_config()
	ensure_dependencies()
end

return M
