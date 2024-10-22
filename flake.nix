{
  description = "A powerful C++ editing experience for your neovim.";

  outputs = inputs @ {parts, ...}:
    parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin" "x86_64-darwin"];

      imports = [
        ./nix/checks.nix
      ];

      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: {
        legacyPackages.vimPlugins = pkgs.callPackage ./default.nix {};

        imports = [
          ./nix/shell.nix
          ./nix/formatter.nix
        ];
      };
    };

  inputs = {
    parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    neorocks.url = "github:nvim-neorocks/neorocks";
  };
}
