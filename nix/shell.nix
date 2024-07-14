{pkgs, lib, ...}: {
  devShells.default = pkgs.mkShellNoCC {
		shellHook = ''
			${lib.getExe pkgs.pre-commit} install
		'';

    packages = [
      pkgs.lua-language-server
      pkgs.luajitPackages.luacheck
			pkgs.luarocks

			pkgs.pre-commit
			pkgs.ruby
			pkgs.stylua
			pkgs.typos
			pkgs.yamllint
			pkgs.actionlint
    ];
  };
}
