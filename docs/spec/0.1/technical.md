# Technical spec of cpp-tools.nvim

## Automatic test runner

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
