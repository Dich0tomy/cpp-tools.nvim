# Technical spec of cpp-tools.nvim

# Table of Contents

<!-- vim-markdown-toc GFM -->

* [Technical spec of cpp-tools.nvim](#technical-spec-of-cpp-toolsnvim)
* [Automatic test runner](#automatic-test-runner)
* [The module system](#the-module-system)
	* [Conventions](#conventions)
	* [Types](#types)
	* [Structure](#structure)
* [luaKITTENS](#luakittens)

<!-- vim-markdown-toc -->

# Technical spec of cpp-tools.nvim

> [!WARNING]
> This is just a draft, some implementation is done already, but I may encounter
> some issues and technical limitations later which may alter whatever is written here.


# Automatic test runner

Each module (lua module, not cpp-tools module) can define its tests by exposing a `__test` function.
The function should contain ordinary busted tests.

This approach is chosen because it's much easier to test the implementation that way.
And while some people argue that it's inelegant and instead only the public interface should be tested,
I found that this approach gives me more flexibility and provides faster feedback while implementing solutions.

The automatic test runner is a file called `auto_test_runner.lua` inside the root `lua` directory.
It's called by busted (see `<root>/.busted`'s `_all.pattern` key) and receives it's context
(global functions for testing + monkey patched assert).

It then scans all lua files in `lua`, evaluates them and collects all that returned a table with the `__test` key,
then calls each of the test functions with the context.

# The module system

TODO: A `CppToolsProject` event, which will fire if neovim is opened up in a project directory.
This is useful to already provide language intelligence features even if we're not in a c/c++ file yet.
E.g. starting the lsp, to be able to use find references.

TODO: Possibly another implicit fields which allows disabling certain events, or just the project event.

## Conventions

1. The types are denoted after `:` and use the [luaKITTENS annotation system](#luaKITTENS).
2. `^` denotes a required field, dependent on some condition (e.g. the `required` - `default` relation).

## Types

1. The `kitty` type refers to a `string` that's a valid `kitten`, that is a valid `luaKITTENS` annotation.
2. The `EventName` type refers to a `string` that's a valid neovim event name, see `:h events`

## Structure

The module system exists to be able to easily define all cpp-tools modules and ensure consistency and compatibility
between all of them.

Each module has its own namespace of form `('cpp-tools.%s'):format(name)` created. It's later used for events.

Each valid cpp-tools module has the following structure:
- **name**: `string` - The name of the module. (This is used for documentation generation as well)
- **description**: `string` - Description of the module (This is used for documentation generation as well)
- **config**: `{ [string]: ConfigEntry }?` - Configuration definition. `ConfigEntry` is defined as follows:
	- **type**: `kitten` - A luaKITTENS annotation denoting the type of this config field.
	- **validate**: `(fn | []any)?` - Either a function that takes in a value and checks if it's valid for the given field
		or an array of valid values. A luaKITTENS type validation happens before this anyway.
	- **required**^: `bool?` - Is this config field mandatory? (This field is not required if `default` is set, it implies `required = false`)
	- **default**^: `any?` - A default value for this config field. Will error if `required = true`. (This field is not required if `required` is set to `false`)

	- **example**^: `string` - An example of this field's usage. If `default` is set and this is not set, it will stringify the `default`'s value and use it instead. (This is used for documentation generation)
	- **description**: `string` - The description for this config field. (This is used for documentation generation)

	Each config additionally has the following **implicit** fields
	- **enable**:
		- **type** - `bool`
		- **required** - `false`
		- **default** - `false`
		- **description** - `('Enables the %s module'):format(name)`

	- **filetypes**:
		- **type** - `[]string`
		- **required** - `false`
		- **default** - `{ 'c', 'cpp' }`
		- **description** - `The filetypes this module should be loaded on.`

	If any module writes their own config fields with the same names, they will not get overridden.
	This is the case for kickstart modules, which are loaded automatically.

- **events**: `{ [EventName]: fn }` - The functions has to have the following signature: `fn(config, ctx): ModuleResult`
	`config` is the evaluated config for this function, `ctx` is the execution context, which currently consists of:
	- **id**: `number` - Autocommand id
	- **event**: `string` - Name of the triggered event
	- **group**: `number` - Autocommand group id
	- **match**: `string` - Expanded value of <amatch>
	- **buf**: `number` - Expanded value of <abuf>
	- **file**: `string` - Expanded value of <afile>
	- **data**: `any` - Arbitrary data passed from `nvim_exec_autocmds()`

- **init**: `fn` - A function called once at the beginning if the module is enabled and the user visited one of the filetypes once.

# luaKITTENS
<!-- TODO: --> Proper spec

For now consult the `lua/cpp-tools/lib/luakittens/parser` file, the `__test` function and the `only_parse()` function.
