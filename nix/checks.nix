{inputs, ...}: {
  perSystem = {
    pkgs,
    system,
    config,
    lib,
    ...
  }: {
    _module.args.pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [inputs.neorocks.overlays.default];
    };

    checks.default = pkgs.writeShellApplication {
      name = "typos-check";

      runtimeInputs = [pkgs.typos];

      text = "typos .";
    };

    checks.neorocks = pkgs.neorocksTest {
      name = "cpp-tools.nvim";

      src = let
        fs = lib.fileset;
        root = ../.;
      in
        fs.toSource {
          inherit root;
          fileset = fs.unions [
            (root + /ftplugin)
            (root + /spec)
            (root + /lua)
            (root + /.busted)
            (fs.fileFilter (f: f.hasExt "rockspec") root)
          ];
        };

      luaPackages = ps: [ps.plenary-nvim];
    };
  };
}
