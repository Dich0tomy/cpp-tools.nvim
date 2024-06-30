local MODREV, SPECREV = "scm", "-1"

package = "cpp-tools.nvim"
version = MODREV .. SPECREV

description = {
   summary = "Supercharge your C++ experience in neovim.",
   homepage = "http://github.com/Dich0tomy/cpp-tools.nvim",
   license = "GPL-3.0"
}

dependencies = { }

source = {
  url = "http://github.com/Dich0tomy/cpp-tools.nvim/archive/v" .. MODREV .. ".zip",
}

if MODREV == "scm" then
  source = {
    url = "git://github.com/Dich0tomy/cpp-tools.nvim",
  }
end


build = {
  type = "builtin",
}
