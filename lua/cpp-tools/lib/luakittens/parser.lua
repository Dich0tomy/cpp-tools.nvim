local M = {}

--[[
1. Parse
2. Remove grammar duplicates
3. Rewrite some grammar
	- `nil|foo` -> `foo?`
	- `a|b|c|any` -> `any`
	- `opt = '?'` -> `opt = true`
3.
]]

--------------------------------------------------
-- Types
--------------------------------------------------

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

---@alias cpp-tools.luakittens.PossibleOptionalType cpp-tools.luakittens.Array|cpp-tools.luakittens.Fundamental|cpp-tools.luakittens.Table|cpp-tools.luakittens.Tuple|cpp-tools.luakittens.Dict

---@class cpp-tools.luakittens.Type
---@field [1] cpp-tools.luakittens.OptionalType | cpp-tools.luakittens.Nil

---@class (exact) cpp-tools.luakittens.OptionalType : cpp-tools.luakittens.Type
---@field [1] cpp-tools.luakittens.PossibleOptionalType
---@field opt string?

---@class (exact) cpp-tools.luakittens.Fundamental
---@field kind cpp-tools.luakittens.TypeKind.Fundamental
---@field type cpp-tools.luakittens.Typename
---
---@class (exact) cpp-tools.luakittens.Nil
---@field kind cpp-tools.luakittens.TypeKind.Fundamental
---@field type cpp-tools.luakittens.Typename.Nil

---@class (exact) cpp-tools.luakittens.Array
---@field kind cpp-tools.luakittens.TypeKind.Array
---@field type cpp-tools.luakittens.Type

---@class (exact) cpp-tools.luakittens.TableElem
---@field key string
---@field val cpp-tools.luakittens.Type

---@class (exact) cpp-tools.luakittens.Table
---@field kind cpp-tools.luakittens.TypeKind.Table
---@field fields cpp-tools.luakittens.TableElem[]

---@class (exact) cpp-tools.luakittens.Tuple
---@field kind cpp-tools.luakittens.TypeKind.Tuple
---@field types cpp-tools.luakittens.Type[]

---@class (exact) cpp-tools.luakittens.Dict
---@field kind cpp-tools.luakittens.TypeKind.Dict
---@field key cpp-tools.luakittens.Type
---@field val cpp-tools.luakittens.Type

---@alias cpp-tools.luakittens.Matches cpp-tools.luakittens.Type[]

--------------------------------------------------
-- End Types
--------------------------------------------------

---Removes duplicates from the list of matches.
--- TODO: In the future just find them and warn about them
--- Warn about optional type shadowing separately
---
---In the case of two types in which one is optional and the other isn't, the one that isn't optional is removed,
---as `T|T?` actually means `T|T|nil`.
---
---@param matches cpp-tools.luakittens.Matches
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
--- - the syntax is more restrictive, the following things are not allowed, because they're illogical:
--- 	- `nil?` - an optional type already means `T|nil`, `nil|nil` doesn't make sense
---
---@param kitty cpp-tools.luakittens.Kitten a luaKITTEN definition
---@return boolean, string|cpp-tools.luakittens.Matches
function M.parse(kitty)
	local grammar = [==[
		grammar <- ws alternative_type ws eof

		alternative_type <- any_type ws ('|' ws alternative_type )*

		any_type <- {| optional_type / nil_type |}
		optional_type <- array_type / dict_type / table_type / tuple_type / fundamental_type opt?

		tuple_type <- '(' ws {:types: {| tuple_elem+ |} :} ws {:kind: ')' -> 'tuple' :}
		tuple_elem <- any_type ws ','? ws

		dict_type <- '{' ws dict_key ws ':' ws dict_val ws  {:kind: '}' -> 'dict' :}
		dict_key <- {:key: '[' ws any_type ws ']' :}
		dict_val <- {:val: any_type :}

		table_type <- '{' ws {:fields: {| table_elem+ |} :} ws {:kind: '}' -> 'table' :}
		table_elem <- {| {:key: ident :} ws ':' ws {:val: any_type :} |} ws ','? ws

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

	return true, remove_duplicates(matches) --[=[@as cpp-tools.luakittens.Matches ]=]
end

---@package
function M.__test()
	assert:set_parameter('TableFormatLevel', 10)

	local fp = require('cpp-tools.lib.fp')
	local parse = fp.chain(M.parse, fp.second)

	local fund = function(t)
		return { kind = 'fundamental', type = t }
	end
	local arr = function(t)
		return { kind = 'array', type = t }
	end
	local tup = function(...)
		return { kind = 'tuple', types = { ... } }
	end
	local dict = function(k, v)
		return { kind = 'dict', key = k, val = v }
	end
	local field = function(k, v)
		return { key = k, val = v }
	end

	describe('`parse()`', function()
		it('Parses single fundamental types', function()
			assert.is.falsy(M.parse('foo'))

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

			assert.is.falsy(M.parse('string[]'))
		end)

		it('Parses tuples', function()
			assert.are.same({ tup(fund('string')) }, parse('(string)'))

			assert.are.same({ tup(fund('string'), fund('number')) }, parse('(string, number)'))

			assert.are.same(
				{ tup(fund('string'), arr(fund('number')), tup(arr(tup(fund('fn'))), fund('bool'))) },
				parse('(string, []number, ([](fn), bool))')
			)
		end)

		it('Parses dicts', function()
			assert.are.same({ dict(fund('string'), fund('fn')) }, parse('{ [string]: fn }'))

			assert.are.same(
				{
					dict(
						dict(fund('string'), arr(fund('fn'))),
						tup(dict(fund('bool'), fund('bool')), arr(dict(fund('fn'), fund('fn'))))
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
				{
					kind = 'table',
					fields = {
						field('foo', fund('fn')),
					},
				},
			}, parse('{ foo: fn }'))

			assert.are.same(
				{
					{
						kind = 'table',
						fields = {
							field('siema n k o ', fund('fn')),
							field('{ "siema n k o ": fn }', arr(fund('bool'))),
						},
					},
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
				{
					kind = 'table',
					fields = {
						field('a', fund('number')),
					},
				},
			}, parse('{ a: number, }'))

			assert.are.same({
				{
					kind = 'table',
					fields = {
						field('a', fund('number')),
						field('b,c,kurwa', fund('string')),
					},
				},
			}, parse([[{ a: number, "b,c,kurwa": string  }]]))

			assert.are.same({ tup(fund('string')) }, parse('(string,)'))

			assert.are.same({ tup(fund('string'), fund('number')) }, parse('(string, number,)'))
		end)

		it('Nil type cannot be optional', function()
			assert.are.same({ fund('nil') }, parse('nil'))
			assert.is.falsy(M.parse('nil?'))
		end)

		it('Alternative is properly parsed', function()
			assert.are.same(
				{ fund('nil'), arr(fund('string')), tup(fund('string'), fund('number')) },
				parse('nil|[]string|(string, number)')
			)
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
end

return M
