local MODREV, SPECREV = 'scm', '-1'

rockspec_format = '3.0'

package = 'cpp-tools.nvim'
version = MODREV .. SPECREV

description = {
   summary = 'Supercharge your C++ experience in neovim.',
   homepage = 'http://github.com/Dich0tomy/cpp-tools.nvim',
   license = 'GPL-3.0'
}
source = {
  url = 'http://github.com/Dich0tomy/cpp-tools.nvim/archive/v' .. MODREV .. '.zip',
}

if MODREV == 'scm' then
  source = {
    url = 'git://github.com/Dich0tomy/cpp-tools.nvim',
  }
end

test_dependencies = {
  'lua >= 5.1',
  'plenary.nvim',
  'nlua',
}

dependencies = {}

build = {
  type = 'builtin',
  copy_directories = {
    'ftplugin'
  },
}
