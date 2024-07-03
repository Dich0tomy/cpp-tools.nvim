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

### Integration with clang-format

### Useful commandline options

### `.clangd`

### Common issues

## Other useful development plugins

## Other useful C/C++ focused plugins
