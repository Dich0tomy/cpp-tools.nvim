-- TODO: Version check here probably
if vim.tbl_get(vim.g, 'cpp_tools', 'enable') == true then
	require('cpp-tools').setup()
end
