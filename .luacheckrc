std = "luajit"
cache = true
include_files = {"spec/**.lua", "lua/**.lua", "*.rockspec", ".luacheckrc"}

read_globals = {
  "vim",
  "describe",
  "it",
  "assert"
}
