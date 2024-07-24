std = "luajit"
cache = true
include_files = {"lua/**.lua", "*.rockspec", ".luacheckrc"}

read_globals = {
  "vim",
  "describe",
  "it",
  "assert"
}
