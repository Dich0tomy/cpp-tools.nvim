# General tips for working with C++ in neovim

This document lists some general useful advice when working with C++ inside neovim.
Some of the things described here are automated by the plugin. Appropriate admonitions are present in such cases.

## Not forcing yourself

This one can be a tough one for some.
We are programmers, we love experimenting, inventing, fiddling and making things work.

Problem arises in certain situations, where the effort put in isn't worth the compensation.
I get it, you love neovim, I love it too! But the first thing you need to understand is that not every tool
is always bound for the job. Neovim with C++ is a good example of that, because while it may and will work for a lot of codebases,
for some the language server, debugging capabilities or refactoring capabilities may simply be.. not enough.

This also applies to specific framework/tooling integrations. In more specialized areas like gamedev (UE), embedded,
automotive or computer vision neovim may not offer the capabilities to integrate with existing tools and architecture.

Sure, you can still use it, but you have to really reflect on your choice and ask yourself if you're not wasting your time
by being stubborn.

This is **especially** important in business.
Your job as a programmer working for company is not writing pretty code or crafting beautiful data structures.
It's also not jumping quickly between pieces of text and flexing your motions in front of colleagues.
Your job as a programmer is to bring value and reduce costs.

If you use neovim for work and it hinders your ability to do that,
because you waste time restarting your clangd, because it's always crashing in your massive codebase,
because the dap/gdb integration is not nearly enough to debug your multi-threaded environment
or you simply don't have a way to integrate with other tools and have to hop between them - you're costing business money.

This is not an attack, I'm not trying to make you feel shameful or stop you from trying to tailor your favourite editor
for your job - but be aware that time is finite and there *may* be more sophisticated tools for the job.

The ability to not be a shill and a fanboy of certain technologies is a very important one for a programmer, especially
one whose job is to bring business value.

## Configuring clangd properly

Apart from having specialized editor integrations we should understand and maximize the usage of our existing tools.

### Integration with clang-tidy

Clangd integrates natively with `clang-tidy`, which is a static analysis tool for C++.
To enable the integration you have to pass in the `--clang-tidy` flag to clangd.

> [!NOTE]
> `cpp-tools.nvim` does that automatically in its default configuration.

To configure clang-tidy, add a `.clang-tidy` file in your project root directory.  
Available options can be explored by running `clang-tidy --help` (grep for `Configuration files`),  
or by visiting [The llvm clang-tidy releases docs](https://releases.llvm.org/18.1.0/tools/clang/tools/extra/docs/clang-tidy/index.html#using-clang-tidy.) (search for `Configuration files` as well).

### Integration with clang-format

Certain language servers offer a builtin formatting capability.
`clangd` does so, but it needs `clang-format` to be present in the environment.

Configuring `clang-format` involves creating a `.clang-format` file with specific formatting options: [Clang-Format style options](https://clang.llvm.org/docs/ClangFormatStyleOptions.html).

### Useful commandline options

Listing and explaining them would be pointless, as the builtin `--help` command already does so very well.
I recommend to run `clangd --help` yourself to see what options are available, some of them are really useful.

### Clangd configuration files

Clangd, as most clang tools allows to create a global or project local configuration file which will further refine its actions.
To configure clangd, place a `.clangd` file in your project root directory and add your options there.

Available options [are listed here](https://clangd.llvm.org/config)

### Common issues

#### clang doesn't work in my code at all

That typically means you haven't generated a [compilation database](https://clangd.llvm.org/installation#project-setup).  
It's a JSON file that maps each file to the command it was compiled with.

For CMake, you have to set the `-DCMAKE_EXPORT_COMPILE_COMMANDS` macro. Meson and certain other build systems generate it automatically.

If your build system doesn't support generating the compilation database, use [`bear`](https://github.com/rizsotto/Bear).

#### clangd doesn't see standard headers

If you're not on Nix, then try everything listed in the official [**Fixing missing system headers**](https://clangd.llvm.org/guides/system-headers#fixing-missing-system-header-issues) section.

If you're on Nix and any of the above don't work, you may be running into [this issue](https://github.com/NixOS/nixpkgs/issues/76486).
The fix for that is setting an environment variable with the path to your clangd, and capturing it in your editor, then using it,
instead of `clangd`, in the command.

>[!NOTE]
> cpp-tools.nvim automatically uses `(os.getenv('CLANGD_PATH') or 'clangd')`

This is how this would look like in Nix:
```nix
mkShell {
  ...

  env.CLANGD_PATH = lib.getExe' pkgs.clang-tools_18 "clangd";
}
```

#### clangd sees `expected` and other similar headers but doesn't see their exposed types and functions

This is due to the fact that these are guarded by special "feature test macros" of form `__cpp_lib_x`, `__cpp_has_x`, etc.

If you already have `clangd` configured you can go to defintion on the header. It should be guarded by something akin to this:
```cpp
#if __cplusplus > 202002L && __cpp_concepts >= 202002L
```
If you `vim.lsp.buf.hover()` on the respective macro names (usually the `K` keymap), you will see their values.
For example, currently, for me, on clangd 18.0.7 `__cplusplus` is defined as `201703`, and `__cpp_concepts` doesn't exist at all.

If your compiler compiles your code *fine*, but clangd doesn't see these, there are two possible fixes:
1. Point clangd to your compiler by appending the [`--query=driver=<path globs>`](https://clangd.llvm.org/guides/system-headers#query-driver) option to the commandline
2. If the above doesn't work, add or modify `.clangd` file in your project root directory with the following content:
```yaml
CompileFlags:
  Add: ['-D__cpp_concepts=202002'] # The exact flags and their values depend on the specific headers and types
```

#### clangd doesn't show full completions for all items

Use the `--completion-style` with `detailed` value.

>[!NOTE]
> cpp-tools.nvim does that automatically.

#### clangd doesn't show all the symbols from my codebase, only the ones from current namespace/scope

Use the `--all-scopes-completion` flag.

>[!NOTE]
> cpp-tools.nvim does that automatically.

#### clangd doesn't complete function args when accepting a completion

Use the `--function-arg-placeholders` flag.

>[!NOTE]
> cpp-tools.nvim does that automatically.

#### clangd doesn't add includes when accepting completion items

Use the `--header-insertion` flag with the `iwyu` value.
Also use `--head-insertion-decorators` for clangd to prepend a dot for completions which will insert an include.

>[!NOTE]
> cpp-tools.nvim does that automatically. It also offers a module which automatically and nicely sorts includes. <!-- TODO: This -->


## Other useful development plugins

TBD.

## Other useful C/C++ focused plugins

TBD.
