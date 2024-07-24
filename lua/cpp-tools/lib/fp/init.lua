local M = {}

---Takes a function of two arguments and flips their parameters
---@generic T, U
---@param fun fun(lhs: `T`, rhs: `U`): any Function to flip
---@return fun(rhs: U, lhs: `T`): any # Flipped function
function M.flip(fun)
	return function(lhs, rhs)
		return fun(rhs, lhs)
	end
end

---Partially applies some function arguments
---@param fun fun(...: any): any Function to apply args to
---@param ... any Args to apply
---@return fun(...: any): any # Function with args applied
function M.partial(fun, ...)
	local passed = { ... }
	return function(...)
		return fun(unpack(vim.list_extend(passed, { ... })))
	end
end

---Partially applies some function arguments to the back
---@param fun fun(...: any): any Function to apply args to
---@param ... any Args to apply
---@return fun(...: any): any # Function with args applied to the back
function M.partial_(fun, ...)
	local passed = { ... }
	return function(...)
		return fun(unpack(vim.list_extend({ ... }, passed)))
	end
end

---Returns the nth argument passed to this function
---@param n number Which argument to return
---@param ... any Args
---@return any # Nth arg
function M.nth(n, ...)
	return ({ ... })[n]
end

---Returns the first argument passed to this function
---@generic T
---@param a `T` The first arg
---@return T # The first argument
function M.first(a)
	return a
end

---Returns the second argument passed to this function
---@generic T
---@param _a any First arg, discarded
---@param b `T` Second arg, returned
---@return T # Second arg
function M.second(_a, b)
	return b
end

---Returns a function that compares its argument to `value`
---@generic T
---@param value `T` Value to compare against
---@return fun(x: T): boolean
function M.equal(value)
	return function(x)
		return x == value
	end
end

---If it's a function, calls it, otherwise returns id
---@generic R, V
---@param value fun(any...): `R`|V Value to call/return
---@param ... any Possible values to pass to the function
---@return R|V
function M.eval(value, ...)
	if type(value) == 'function' then
		return value(...)
	else
		return value
	end
end

---Returns the result of a function wrapped in an array
---@generic Ts
---@param f fun(any...): `Ts` Function to wrap
---@return fun(...): [Ts]
function M.arraified(f)
	return function(...)
		return { f(...) }
	end
end

---Returns the args untouched
---@param ... any Args to return
---@return ... any
function M.id(...)
	return ...
end

---Returns `id` or the passed in function
---@generic Rs, Ts
---@param value fun(...: `Ts`): `Rs`|nil Value to call/return
---@return fun(...: Ts): `Rs`|fun(...: any): ...
function M.maybe_fn(value)
	assert(type(value) == 'function' or value == nil)

	if type(value) == 'function' then
		return value
	else
		return M.id
	end
end

---Reduces the result over a function
---@generic T, U, R
---@param f fun(arg1: T, arg2: U): `R` The applied function
---@param acc R The accumulator and initial value
---@return R
function M.foldl(f, acc, ...)
	if select('#', ...) == 0 then
		return acc
	end
	local l = ...
	return M.foldl(f, f(acc, l), select(2, ...))
end

---Composes two functions f, g and into `g(f(...))`
---@generic FirstR, SecondR
---@param f fun(...: any): `FirstR`
---@param g fun(...: FirstR): `SecondR`
---@return fun(...: any): SecondR
function M.compose(f, g)
	return function(...)
		return g(f(...))
	end
end

---Chains several functions invocations together
---chain(a, b, c) results in c(b(a(...)))
---@param ... fun(...: any): ...
---@return fun(...: any): ...
function M.chain(...)
	return M.foldl(M.compose, M.id, ...)
end

---Returns `not f(...)`
---@param f fun(...: any): boolean func to inverse
---@return fun(...: any): boolean
function M.nah(f)
	return function(...)
		return not f(...)
	end
end

---Formats the arguments
---@param str string The format string
---@return fun(...: any): string
function M.fmt(str)
	return function(...)
		return str:format(...)
	end
end

function M.__test()
	describe('`flip()`', function()
		it('Flips a two arg function', function()
			local sub = function(a, b)
				return a - b
			end

			assert.are.same(sub(5, 3), 2)
			assert.are.same(M.flip(sub)(5, 3), -2)
		end)

		it('Makes a one arg function accept only the second argument', function()
			assert.are.same(M.id(5), 5)
			assert.are.same(M.flip(M.id)(5, 3), 3)
		end)
	end)

	describe('`partial()`', function()
		it('Applies the first argument', function()
			local sub = function(a, b)
				return a - b
			end

			assert.are.same(M.partial(sub, 5)(3), 2)
		end)

		it('Applies all arguments', function()
			local sub = function(a, b)
				return a - b
			end

			assert.are.same(M.partial(sub, 5, 3)(), 2)
		end)
	end)

	describe('`partial_()`', function()
		it('Applies the last argument', function()
			local sub = function(a, b)
				return a - b
			end

			assert.are.same(M.partial_(sub, 5)(3), -2)
		end)

		it('Applies all arguments', function()
			local sub = function(a, b)
				return a - b
			end

			assert.are.same(M.partial_(sub, 5, 3)(), 2)
		end)
	end)

	describe('`partial_()`', function()
		it('Applies the last argument', function()
			local sub = function(a, b)
				return a - b
			end

			assert.are.same(M.partial_(sub, 5)(3), -2)
		end)

		it('Applies all arguments', function()
			local sub = function(a, b)
				return a - b
			end

			assert.are.same(M.partial_(sub, 5, 3)(), 2)
		end)
	end)
end

return M
