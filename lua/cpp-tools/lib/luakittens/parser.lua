local M = {}

--------------------------------------------------
-- Types
--------------------------------------------------

--[[

This is a very basic implementation, but I will rewrite the parsing to use a handwritten parser
because the lpeg re implementation isn't sufficient and doesn't allow for any remotely useful diagnostics.

The current implementation lacks the ability to express alternative types in complex types.
The blocker is that with this lpeg parser it's impossible to not make things like `[]string|number` ambiguous
(this gets parsed as `[](string|number)`).

]]

---@alias cpp-tools.luakittens.Kitten string

---@package
---@enum cpp-tools.luakittens.TypeKind
local TypeKind = {
	Fundamental = 'fundamental',
	Array = 'array',
	Dict = 'dict',
	Table = 'table',
	Tuple = 'tuple',
}

---@package
---@enum cpp-tools.luakittens.Typename
local Typename = {
	Nil = 'nil',
	Any = 'any',
	String = 'string',
	Number = 'number',
	Table = 'table',
	Fn = 'fn',
	Bool = 'bool',
}

--------------------------------------------------
-- End Types
--------------------------------------------------

--------------------------------------------------
-- AST type constructors
--------------------------------------------------

local function fund(t)
	return { kind = 'fundamental', type = t }
end

local function arr(t)
	return { kind = 'array', type = t }
end

local function tuple(...)
	return { kind = 'tuple', types = { ... } }
end

local function dict(k, v)
	return { kind = 'dict', key = k, val = v }
end

local function field(k, v)
	return { key = k, val = v }
end

local function tab(...)
	return { kind = 'table', fields = { ... } }
end

--- Adds `opt = '?'` into the type, thus marking it as optional
---
local function make_opt(type)
	type.opt = '?'
	return type
end

--------------------------------------------------
-- End AST type constructors
--------------------------------------------------

---Normalizes the resulting AST:
--- - `T|nil` -> `foo?`
--- - `T|U|...|any` -> `any`
---
local function normalize(matches)
	local nil_idx = nil
	local has_nil = vim.iter(ipairs(matches)):any(function(i, m)
		if m.kind == TypeKind.Fundamental and m.type == Typename.Nil then
			nil_idx = i
			return true
		end
		return false
	end)

	local has_any = vim.iter(matches):any(function(m)
		return m.type == Typename.Any
	end)

	local prev_matches_size = #matches

	if has_any then
		matches = { fund('any') }
	end

	if has_nil and (prev_matches_size == 2 or has_any) then
		table.remove(matches, nil_idx)
		return { make_opt(matches[1]) }
	end

	return matches
end

---Removes duplicates from the list of matches.
--- TODO: In the future just find them and warn about them
--- Warn about optional type shadowing separately
---
---In the case of two types in which one is optional and the other isn't, the one that isn't optional is removed,
---as `T|T?` actually means `T|T|nil`.
---
local function remove_duplicates(matches)
	local iter = require('cpp-tools.lib.iter')

	local strip_opt = function(match)
		local m = vim.fn.copy(match)
		m.opt = nil
		return m
	end

	local trivial_remove_duplicates = function(matches)
		local out = {}

		vim.iter(matches):each(function(m)
			if not vim.iter(out):find(function(x)
				return vim.deep_equal(x, m)
			end) then
				table.insert(out, m)
			end
		end)

		return out
	end

	local opt_matches, matches = iter.partition(matches, function(m)
		return vim.tbl_get(m, 'opt')
	end)

	vim.iter(ipairs(matches)):each(function(i, m)
		vim.iter(opt_matches):each(function(om)
			if vim.deep_equal(strip_opt(om), m) then
				table.remove(matches, i)
			end
		end)
	end)

	return vim.tbl_extend('error', trivial_remove_duplicates(matches), trivial_remove_duplicates(opt_matches))
end

---Parses a type annotation with a grammar similar to that of luaCATS - luaKITTENS
---
---The differences are:
---	- only `nil`, `any`, `string`, `number`, (`function`/`fn`), (`boolean`/`bool`), `table` fundamental types are supported
--- - no support for function types (only `function` or `fn` are allowed)
--- - booleans can be typed both as `bool` and `boolean`
--- - arrays use the `[]type` syntax instead of `type[]`
--- - tuples use `()` instead of `[]`
--- - the key-value table syntax (`table<T, U>`) is not supported, instead only the dict version exists - `{ [T]: U }`
--- - the syntax is more restrictive, the following things are not allowed:
--- 	- `nil?` - an optional type already means `T|nil`, `nil|nil` doesn't make sense
---
---@param kitty cpp-tools.luakittens.Kitten a luaKITTEN definition
---@return boolean, string|table
local function only_parse(kitty)
	local grammar = [==[
		grammar <- ws alternative_type ws eof

		alternative_type <- any_type ws ('|' ws alternative_type )*

		any_type <- optional_type / {| nil_type |}
		optional_type <- {| array_type / dict_type / table_type / tuple_type / fundamental_type opt? |}

		tuple_type <- '(' ws {:types: {| tuple_elem+ |} :} ws {:kind: ')' -> 'tuple' :}
		tuple_elem <- any_type ws ','? ws

		dict_type <- '{' ws dict_key ws ':' ws dict_val ws  {:kind: '}' -> 'dict' :}
		dict_key <- {:key: '[' ws optional_type ws ']' :}
		dict_val <- {:val: optional_type :}

		table_type <- '{' ws {:fields: {| table_elem+ |} :} ws {:kind: '}' -> 'table' :}
		table_elem <- {| {:key: ident :} ws ':' ws {:val: optional_type :} |} ws ','? ws

		array_type <-  {:kind: '[]' -> 'array' :} {:type: any_type :}

		fundamental_type <- {:type: typename :} {:kind: '' -> 'fundamental' :}

		nil_type <- {:type: 'nil' :} {:kind: '' -> 'fundamental' :}

		typename <- 'any' / 'string' / 'number' / 'table' / function_typename / boolean_typename
		boolean_typename <- {~ ('boolean' / 'bool') -> 'bool' ~}
		function_typename <- {~ ('function' / 'fn') -> 'fn' ~}

		opt <- {:opt: '?' :}

		ident <- escaped_ident / basic_ident

		basic_ident <- [a-zA-Z_][a-zA-Z0-9_]*
		escaped_ident <- {:used_quote: quote :} { (!(=used_quote) .)+ } =used_quote

		quote <- "'" / '"'

		eof <- !.
		ws <- %s*
	]==]

	local pattern = vim.re.compile(grammar)

	local matches = { pattern:match(kitty) }

	if not matches or vim.tbl_isempty(matches) then
		return false, 'Cannot parse kitty\'s grammar.'
	end

	return true, matches
end

---Parses a type annotation with a grammar similar to that of luaCATS - luaKITTENS
---
---The differences are:
---	- only `nil`, `any`, `string`, `number`, (`function`/`fn`), (`boolean`/`bool`), `table` fundamental types are supported
--- - no support for function types (only `function` or `fn` are allowed)
--- - booleans can be typed both as `bool` and `boolean`
--- - arrays use the `[]type` syntax instead of `type[]`
--- - tuples use `()` instead of `[]`
--- - the key-value table syntax (`table<T, U>`) is not supported, instead only the dict version exists - `{ [T]: U }`
--- - the syntax is more restrictive, the following things are not allowed:
--- 	- `nil?` - an optional type already means `T|nil`, `nil|nil` doesn't make sense
---
---@param kitty cpp-tools.luakittens.Kitten a luaKITTEN definition
---@return boolean, string|table
function M.parse(kitty)
	local ok, matches = only_parse(kitty)

	if not ok then
		return ok, matches
	end

	return ok, normalize(remove_duplicates(matches))
end

---@package
function M.__test()
	assert:set_parameter('TableFormatLevel', 10)

	local fp = require('cpp-tools.lib.fp')
	local parse = fp.chain(only_parse, fp.second)

	describe('`only_parse()`', function()
		it('Parses single fundamental types', function()
			assert.is.falsy(only_parse('foo'))

			assert.are.same({ fund('string') }, parse('string'))
			assert.are.same({ fund('number') }, parse('number'))
			assert.are.same({ fund('nil') }, parse('nil'))
			assert.are.same({ fund('any') }, parse('any'))

			assert.are.same({ fund('fn') }, parse('fn'))
			assert.are.same({ fund('fn') }, parse('function'))
			assert.are.same({ fund('bool') }, parse('bool'))
			assert.are.same({ fund('bool') }, parse('boolean'))
		end)

		it('Parses arrays', function()
			assert.are.same({ arr(fund('string')) }, parse('[]string'))

			assert.are.same({ arr(arr(fund('string'))) }, parse('[][]string'))

			assert.is.falsy(only_parse('string[]'))
		end)

		it('Parses tuples', function()
			assert.are.same({ tuple(fund('string')) }, parse('(string)'))

			assert.are.same({ tuple(fund('string'), fund('number')) }, parse('(string, number)'))

			assert.are.same(
				{ tuple(fund('string'), arr(fund('number')), tuple(arr(tuple(fund('fn'))), fund('bool'))) },
				parse('(string, []number, ([](fn), bool))')
			)
		end)

		it('Parses dicts', function()
			assert.are.same({ dict(fund('string'), fund('fn')) }, parse('{ [string]: fn }'))

			assert.are.same(
				{
					dict(
						dict(fund('string'), arr(fund('fn'))),
						tuple(dict(fund('bool'), fund('bool')), arr(dict(fund('fn'), fund('fn'))))
					),
				},
				parse([=[
				{
					[{ [string]: []fn }]:
					({ [bool]: bool }, []{ [fn]: fn })
				}
				]=])
			)
		end)

		it('Parses tables', function()
			assert.are.same({
				tab(field('foo', fund('fn'))),
			}, parse('{ foo: fn }'))

			assert.are.same(
				{
					tab(field('siema n k o ', fund('fn')), field('{ "siema n k o ": fn }', arr(fund('bool')))),
				},
				parse([[
				{
					"siema n k o ": fn,
					'{ "siema n k o ": fn }': []bool
				}
				]])
			)
		end)

		it('Allows for trailing commas', function()
			assert.are.same({
				tab(field('a', fund('number'))),
			}, parse('{ a: number, }'))

			assert.are.same({
				tab(field('a', fund('number')), field('b,c,kurwa', fund('string'))),
			}, parse([[{ a: number, "b,c,kurwa": string  }]]))

			assert.are.same({ tuple(fund('string')) }, parse('(string,)'))

			assert.are.same({ tuple(fund('string'), fund('number')) }, parse('(string, number,)'))
		end)

		it('Nil type cannot be optional', function()
			assert.are.same({ fund('nil') }, parse('nil'))
			assert.is.falsy(only_parse('nil?'))
		end)

		it('Alternative is properly parsed', function()
			assert.are.same(
				{ fund('nil'), arr(fund('string')), tuple(fund('string'), fund('number')) },
				parse('nil|[]string|(string, number)')
			)
		end)

		it('Nil is prohibited in dict', function()
			assert.are.falsy(only_parse('{ [string]: nil }'))
			assert.are.falsy(only_parse('{ [nil]: string }'))
		end)

		it('Nil is prohibited in table', function()
			assert.are.falsy(only_parse('{ foo: nil }'))
		end)

		it('Nil is prohibited in table', function()
			assert.are.falsy(only_parse('{ foo: nil }'))
		end)
	end)

	describe('`remove_duplicates()`', function()
		it('Leaves out a single type', function()
			assert.are.same(parse('string'), remove_duplicates(parse('string')))
		end)

		it('Removes duplicates', function()
			assert.are.same(parse('string|number'), remove_duplicates(parse('string|number|string|number')))
		end)

		it('Prefers optional types', function()
			assert.are.same(parse('string?'), remove_duplicates(parse('string?|string')))

			assert.are.same(parse('string?'), remove_duplicates(parse('string|string?')))
		end)
	end)

	describe('`normalize()`', function()
		it('Leaves out normal types', function()
			local ast = parse('string')
			assert.are.same(ast, normalize(ast))

			ast = parse('string|(number, string)|{ "lampa jak skurwysyn": []fn }')
			assert.are.same(ast, normalize(ast))

			ast = parse('any')
			assert.are.same(ast, normalize(ast))

			ast = parse('nil')
			assert.are.same(ast, normalize(ast))
		end)

		it('Turns `T|nil` into `T?`', function()
			local ast = { make_opt(fund('string')) }
			assert.are.same(ast, normalize(parse('string|nil')))
			assert.are.same(ast, normalize(parse('nil|string')))
		end)

		it('Turns `T|U|...|any` into `any`', function()
			local ast = { fund('any') }
			assert.are.same(ast, normalize(parse('string|(fn, bool, any)|any')))
		end)

		it('Turns `T|U|...|any|nil` into `any?`', function()
			local ast = { make_opt(fund('any')) }
			assert.are.same(ast, normalize(parse('string|(fn, bool, any)|any|nil')))
		end)
	end)
end

return M
