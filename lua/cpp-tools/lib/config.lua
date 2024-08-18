---@module 'cpp-tools.lib.types'

local M = {}

---@class (exact) cpp-tools.config.ConfigFieldSpec
---@field type string|string[] The type of the field, currently only lua types are allowed.
---@field validator nil|any[]|fun(in: any): boolean, string Either an array of allowed values or a function that takes in the value
---and returns if the validation succeeded and what the error is. Defaults to `function() return true end`.
---@field required boolean? Is this required? Defaults to `true`.
---@field default nil|any (Required if `required` is `false`!!!) A default value for this option. If required isn't set it implies `required = false`.
---@field example string An example (used for generating documentation).
---@field description string A description (used for generating documentation).

---@alias cpp-tools.config.ConfigSpec table<string, cpp-tools.config.ConfigFieldSpec>
---@alias cpp-tools.config.UserConfig table<string, any>

---Returns implicit fields for a module
---@param name string Module's name
---@return cpp-tools.config.ConfigSpec
local function create_implicit_fields(name)
	---@type cpp-tools.config.ConfigSpec
	return {
		enable = {
			type = 'boolean',
			required = true,
			example = 'false',
			description = ([[Whether to enable the '%s' module]]):format(name),
		},

		filetypes = {
			type = { 'string', '[]string' },
			required = false,
			default = { 'c', 'cpp' },
			example = [[{ 'c', 'cpp' }]],
			description = [[The filetypes for which this module should be setup and run]],
		},
	}
end

---Adds implicit fields to the config's spec
---@param name string Module's name
---@param config_spec cpp-tools.config.ConfigSpec The configuration spec
local function add_implicit_fields(name, config_spec)
	local implicit_fields = create_implicit_fields(name)

	return vim.tbl_extend('keep', config_spec, implicit_fields)
end

function M.get_config()
	return vim.tbl_extend_deep('force', vim.g.cpp_tools_global or {}, vim.g.cpp_tools or {})
end

---Evaluates a configuration for a module
---@param name string The module name
---@param config_spec cpp-tools.config.ConfigSpec
---@param runtime_value cpp-tools.config.UserConfig
function M.evaluate(name, config_spec, runtime_value)
	config_spec = add_implicit_fields(name, config_spec)

	local evaluated_config = {}
	-- TODO: Add context with levenshtein distance and such
	local potential_errors = {}

	local did_error = false
	-- TODO: Refactor into a function, to also use inside healtcheck
	for field_name, definition in pairs(config_spec) do
		local field_value = runtime_value[field_name]
		local field_spec = config_spec[field_name]

		if field_value == nil and field_spec.required then
			did_error = true

			table.insert(potential_errors, ('Field `%s` is required but a value for it wasn\'t provided.'):format(field_name))
		end

		if field_value and not M.validate_type(field_value, field_spec) then
			did_error = true

			table.insert(
				potential_errors,
				('Field `%s` is expected to have type `%s`. Instead, it is of type "%s".'):format(
					field_name,
					config_spec[field_name].type,
					type(field_value)
				)
			)
		end

		if did_error then
			goto continue
		end

		if field_value == nil then
			evaluated_config[field_name] = definition.default
		else
			evaluated_config[field_name] = field_value
		end

		::continue::
		runtime_value[field_name] = nil
	end

	for field_name, _value in pairs(runtime_value) do
		table.insert(potential_errors, ('Extraneous field `%s` given.'):format(field_name))
	end

	if #potential_errors ~= 0 then
		return false, potential_errors
	end

	return true, evaluated_config
end

---Checks if the runtime value for a config field has the correct type
---@param field_value any The runtime value of a field
---@param field_spec cpp-tools.config.ConfigFieldSpec The specification for the field
---@return boolean
function M.validate_type(field_value, field_spec)
	-- TODO: Luakittens validation
	if type(field_spec.type) == 'table' then
		return vim.iter(field_spec.type):any(function(expected_type)
			return expected_type == type(field_value)
		end)
	end

	return type(field_value) == field_spec.type
end

---Evaluates only the documentation part of a config.
---@param name string The module name
---@param config table<string, cpp-tools.config.ConfigFieldSpec>
function M.evaluate_docs(name, config) end

---@package
function M.__test(testfiles)
	-- TODO: Validate each module's config spec
	describe('`add_implicit_fields()`', function()
		it('Adds fields if they don\'t exist', function()
			local name = 'test'

			local spec = add_implicit_fields(name, {})
			local implicit_fields = create_implicit_fields(name)

			assert.are.equal(vim.tbl_count(spec), vim.tbl_count(implicit_fields))
			assert.are.same(spec, implicit_fields)
		end)

		it('Ignores fields that already exist', function()
			local name = 'test'

			local implicit_fields = create_implicit_fields(name)

			local field_name, field_val = vim.iter(vim.deepcopy(implicit_fields)):nth(1)
			field_val.required = not field_val.required

			local changed_spec = add_implicit_fields(name, { [field_name] = field_val })

			assert.are.equal(vim.tbl_count(changed_spec), vim.tbl_count(implicit_fields))
			assert.are.no.same(changed_spec[field_name].required, implicit_fields[field_name].required)
		end)
	end)

	describe('`evaluate()`', function()
		it('Properly evaluates a good config', function()
			local spec = {
				text = {
					type = { 'function', 'string' },
				},
				comment_style = {
					type = 'string',
					validate = { 'c', 'cpp' },
				},
			}

			local value = {
				enable = false, -- Implicit required field
				text = 'foo',
				comment_style = 'c',
			}

			local ok, evaluated_config = M.evaluate('test', spec, vim.deepcopy(value))

			assert.message(evaluated_config).truthy(ok)
			assert.are.equal(value.enable, evaluated_config.enable)
			assert.are.equal(value.text, evaluated_config.text)
			assert.are.equal(value.comment_style, evaluated_config.comment_style)
		end)

		it('Properly evaluates a good config with default values', function()
			local spec = {
				comment_style = {
					type = 'string',
					default = 'cpp',
					validate = { 'c', 'cpp' },
				},
			}

			local value = {
				enable = true, -- Implicit required field
			}

			local ok, evaluated_config = M.evaluate('test', spec, vim.deepcopy(value))

			assert.message(evaluated_config).truthy(ok)
			assert.are.equal(value.enable, evaluated_config.enable)
			assert.are.equal('cpp', evaluated_config.comment_style)
		end)

		it('Properly evaluates a good config and overrides implicit fields', function()
			local spec = {
				enable = {
					default = true,
					type = 'boolean',
				},
				comment_style = {
					type = 'string',
					default = 'cpp',
					validate = { 'c', 'cpp' },
				},
			}

			local value = {}

			local ok, evaluated_config = M.evaluate('test', spec, vim.deepcopy(value))

			assert.message(evaluated_config).truthy(ok)
			assert.are.equal(true, evaluated_config.enable)
			assert.are.equal('cpp', evaluated_config.comment_style)
		end)

		it('Errors on not providing required value', function()
			local spec = {} -- Will only get the implicit fields

			local value = {}

			local ok, evaluated_config = M.evaluate('test', spec, vim.deepcopy(value))

			assert.message(evaluated_config).falsy(ok)
			assert.message(evaluated_config).are.same(1, vim.tbl_count(evaluated_config))
		end)

		it('Errors on extraneous fields', function()
			local spec = {} -- Will only get the implicit fields

			local value = {
				enable = true,
				foo = 1,
				bar = 1,
			}

			local ok, evaluated_config = M.evaluate('test', spec, vim.deepcopy(value))

			assert.message(evaluated_config).falsy(ok)
			assert.message(evaluated_config).are.same(2, vim.tbl_count(evaluated_config))
		end)

		it('Errors on wrong type', function()
			local spec = {}

			local value = {
				enable = 'hello',
			}

			local ok, evaluated_config = M.evaluate('test', spec, vim.deepcopy(value))

			assert.message(evaluated_config).falsy(ok)
			assert.message(evaluated_config).are.same(1, vim.tbl_count(evaluated_config))
		end)

		it('Returns all the errors', function()
			local spec = {
				bar = {
					type = 'string',
				},
			}

			local value = {
				-- Lack of required enable field
				bar = 1, -- Wrong bar type
				foo = 1, -- Extraneous foo field
			}

			local ok, evaluated_config = M.evaluate('test', spec, vim.deepcopy(value))

			assert.message(evaluated_config).falsy(ok)
			-- We expect two, because in this case it will both error about the type
			-- being wrong and about extraneous field
			assert.message(evaluated_config).are.same(3, vim.tbl_count(evaluated_config))
		end)
	end)

	-- TODO: Refactor based on M.evaluate and parse_structure into a helper to lib.test
	local function parse_config_spec(was_ok, spec)
		if not was_ok then
			return false, spec
		end

		local config = spec.config

		local fields = {
			type = { 'string', 'table' },
			description = 'string',
		}

		local function type_valid(field, valid_type)
			if type(valid_type) == 'table' then
				return vim.iter(valid_type):any(function(vt)
					return vt == type(field)
				end)
			else
				return valid_type == type(field)
			end
		end

		for spec_field_name, spec in pairs(config) do
			for field_name, required_type in pairs(fields) do
				local field = vim.tbl_get(spec, field_name)

				if field == nil then
					return false, ('In `%s` - `%s` required field lacking'):format(spec_field_name, field_name)
				else
					local fields_type = type(field)
					if not type_valid(field, required_type) then
						return false,
							('In `%s` - `%s`\'s type is `%s` - `%s` was expected.'):format(
								spec_field_name,
								field_name,
								fields_type,
								required_type
							)
					end
				end
			end

			if vim.tbl_get(spec, 'example') == nil and vim.tbl_get(spec, 'default') == nil then
				return false, ('In `%s` - either \'example\' or \'default\' need to be specified.'):format(spec_field_name)
			end

			if vim.tbl_get(spec, 'required') == nil and vim.tbl_get(spec, 'default') == nil then
				return false, ('In `%s` - `required` needs to be specified if `default` isn\t present.'):format(spec_field_name)
			end

			if vim.tbl_get(spec, 'required') == true and vim.tbl_get(spec, 'default') ~= nil then
				return false, ('In `%s` - `default` cannot be set if `required == true`.'):format(spec_field_name)
			end
		end

		return true, 'ok'
	end

	describe('cpp-tools.nvim modules', function()
		local paths = require('cpp-tools.lib.paths')

		it('[sanity check - incorrect modules should fail]', function()
			local test_mods_dir = testfiles .. '/lib/config/config_specs_test'

			local test_mods = vim
				.iter(paths.try_bulk_require(test_mods_dir))
				:map(function(bulk_require_result)
					return {
						path = bulk_require_result.path,
						result = { parse_config_spec(unpack(bulk_require_result.result)) },
					}
				end)
				:totable()

			assert.are.no.equal(#test_mods, 0)

			for _, result in ipairs(test_mods) do
				assert.message(('File [%s] - %s'):format(result.path, result.result[2])).is.falsy(result.result[1])
			end
		end)

		--[[ it('All have valid config structure', function()
			local root = require('cpp-tools.lib.test').root()
			local modules_dir = root .. '/lua/cpp-tools/modules'

			local parsed_mods =
			vim.iter(paths.try_bulk_require(modules_dir, { depth = 10 }))
				:map(function(bulk_require_result)
					return {
						path = bulk_require_result.path,
						result = { parse_config_spec(unpack(bulk_require_result.result)) }
					}
				end)
				:totable()

			assert.are.no.equal(#parsed_mods, 0)

			for _, result in ipairs(parsed_mods) do
				assert
				.message(('File [%s] - %s'):format(result.path, result.result[2]))
				.is.truthy(result.result[1])
			end
		end) ]]
	end)
end

return M
