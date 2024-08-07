# Table of Contents

<!-- vim-markdown-toc GFM -->

* [Functional spec of cpp-tools.nvim](#functional-spec-of-cpp-toolsnvim)
* [What is cpp-tools.nvim](#what-is-cpp-toolsnvim)
	* [Main objectives](#main-objectives)
	* [Installation](#installation)
		* [Using Nix](#using-nix)
		* [Using rocks.nvim](#using-rocksnvim)
		* [Using lazy.nvim](#using-lazynvim)
	* [Usage & configuration](#usage--configuration)
	* [General info](#general-info)
* [Definitions](#definitions)
* [Events](#events)
* [Goals for *some* future release](#goals-for-some-future-release)
* [Goals for this release](#goals-for-this-release)
* [Goals for the **next** release](#goals-for-the-next-release)
* [Non-goals for **any** release](#non-goals-for-any-release)
* [Not sure if I'll ever implement these](#not-sure-if-ill-ever-implement-these)
	* [Stash (For things that are not categorized or well though of yet)](#stash-for-things-that-are-not-categorized-or-well-though-of-yet)
* [Known issues and questions](#known-issues-and-questions)

<!-- vim-markdown-toc -->

# Functional spec of cpp-tools.nvim

> [!NOTE]
> This is a **pre implementation** draft, which means it's *just* an idea and no code yet.
> It may change if I see some technical limitations.

# What is cpp-tools.nvim

cpp-tools.nvim is a neovim plugin that aims to improve the experience of C++ development under neovim.

By default, OOTB it provides a sensible, carefully crafted, default C++ configuration.  
It also contains a plethora of modules for making the C++ experience smooth, including modules for generating code,
exploring documentation, etc.

## Main objectives

- [x] Provide a sensible default implementation OOTB
- [x] Provide several modules which address pain points when working with C++ in neovim
- [x] Provide several modules with niceities, like inserting comment preambles, header guards, etc.
- [x] TBD.

## Installation

<!-- TODO: This -->

### Using Nix

### Using rocks.nvim

### Using lazy.nvim

## Usage & configuration

> [!IMPORTANT]
> Disable all LSP, Dap and <!-- TODO: This --> configuration you do manually.

The simplest usage is just installing the plugin, it will automatically enable a number of modules, which
activate the LSP, dap and .... with no configuration needed.

Some of the modules rely on some specific configuration.
In general, the most basic configuration requires you to tell `cpp-tools.nvim` how your project is structured.
To create project-specific configuration, create `.nvim.lua` in the root directory and set the `vim.opt.exrc` option to `true` in your config.

cpptools needs to know if your project is structured into several subprojects (for example library, binary and tests)
and what their source and include directories are.

The simplest way is to tell `cpptools` the general `src` path, which contains source and header files/projects/is the only project dir.
Cpptools will try to guess the correct directories. E.g.:

```lua
vim.g.cpptools = {
  -- Each given directory must be relative to project root.
  -- For this valid values are `.` if your code is in root or `<name>` of the directory where your projects reside
  -- cpptools has heuristics for a single dir with all the files, several subprojects with all the files,
  -- several subprojects with include/ and src/, etc., etc.
  projects = 'src',
}
```
Upon successful guess, cpptools will prompt you with the determined projects and directories.
You can accept the configuration or discard it, open your `.nvim.lua` file and type it manually:
```lua
vim.g.cpptools = {
  projects = {
    name = {
      include = "<path>",
      src = "<path>",
    }
 };
}
```

## General info

# Definitions

...

# Events

The plugin defines and responds to the following autocommand events:
- `CppToolsProject` - Fires once some time after neovim is opened and the current working directory is detected
	to be a C++ project. It is used by some modules to start some stuff that is useful outside of the listed filetypes,
		for example starting a language server on startup, to provide global workspace symbols and such out of the box.
		If you don't want a certain module to respond to this event, you can set the `disable_project_event` option to `true`.

# Goals for *some* future release

# Goals for this release

- Core:
  - [ ] Automatic setting up of LSP, dap, ?

- Productivity:
  - [ ] Completion actions - enables additional keybinds for completions to automatically `std::move`, `std::forward` and such
    when accepting a completion. Both are configurable to also expand to macros or `static_cast` if that's the convention in
    the project.

- Generation:
  - [ ] Preamble - inserts comment with a copyright, license, etc. to all files if it isn't there
  - [ ] Header guard - inserts a `#pragma once` or a configured classic `#ifndef` header guard if it isn't in a header

# Goals for the **next** release

# Non-goals for **any** release

# Not sure if I'll ever implement these

## Stash (For things that are not categorized or well though of yet)
 - [ ] Find a way to reliably have access to the language server's features outside of C++ files.
 - [ ] The problem with just attaching a client to any buffers will try to do things with the buffer - parse it, show diagnostics, etc.
 - [ ] Some way to still provide go to definition even for semantic errors?
 - [ ] Some way to easily check the versions of dependencies and general project info
 - [ ] Better insert adding. If a symbol has been used manually and has a valid insert we insert a header lmao.

- Linting:
  - [ ] Better integration with iwyu and such

- Intelligence:
	- [ ] Better lsp symbols with filtering and whatnot

- Productivity:
  - [ ] Automatically define templates based on the contents
  - [ ] .as, .each, etc.
  - [ ] <C-o> like, but one that returns absolutely from the code (esp. internal ones), not just back
  - [ ] Automatic implementation of specific traits and such - fmt, etc.
  - [ ] Quickly imports a header from the current header directory

- Readability:
  - [ ] Change the inline hints to contain pointer/reference information
  - [ ] Allow adding highlighting for member things and such
  - [ ] Builtin C++filt and the like
  - [ ] Something to make it easier to work with sanitizers output

- Documentation:
  - [ ] Gives you an outline of a header file/several ones (K map)
  - [ ] Gives you an outline of a given std::type

- Generation:
  - [ ] Generating classes, templates, and such

- Refactoring:
  - [ ] Automatic include paths changing when moving files
  - [ ] Refactor things like std::async(&foo, this, a, b) into foo(a, b)
  - [ ] Select a range and click a button to turn it into a lambda
  - [ ] https://www.jetbrains.com/help/clion/refactoring-source-code.html#popular-refactorings
  - [ ] https://discord.com/channels/@me/843509153266794546/1257069439728484442
  - [ ] Automatic generation of cpp files based on already existing hpp files
  - [ ] Remove redefinitions
  - [ ] Node Actions:
  - [ ] - on const -> change to left/right
  - [ ] Track function signatures and update them on change. Add an option to change the signature based on call.
  - [ ] E.g. the sig is `void(int)`, but you call it with `void(int, int)`.
  - [ ] Automatic dependency injection, if I change `foo()` to `foo(5)` it will change the sig

- Build:
  - [ ] Temporary quick test files
  - [ ] CMake, Meson etc.?

- Binary:
  - [ ] Querying asm from functions, code parts (SteelPh0enix)

# Known issues and questions
