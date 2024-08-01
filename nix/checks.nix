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

		checks.pre-commit = pkgs.writeShellApplication {
			name = "pre-commit-check";

			runtimeInputs = [pkgs.pre-commit];

			text = "pre-commit run --all-files";
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
            (root + /testfiles)
            (root + /ftplugin)
            (root + /lua)
            (root + /.busted)
            (fs.fileFilter (f: f.hasExt "rockspec") root)
          ];
        };

      luaPackages = ps: [ps.plenary-nvim];
    };

    checks.luacheck = pkgs.writeShellApplication {
      name = "luacheck";

      runtimeInputs = [pkgs.luajitPackages.luacheck];

      text = "luacheck .";
    };
  };
}
