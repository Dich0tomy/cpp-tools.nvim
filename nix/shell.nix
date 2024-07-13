{pkgs, ...}: {
  devShells.default = pkgs.mkShellNoCC {
    packages = [
      pkgs.lua-language-server
    ];
  };
}
