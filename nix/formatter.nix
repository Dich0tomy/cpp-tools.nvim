{pkgs, ...}: {
  formatter = pkgs.writeShellApplication {
    name = "cpp-tools-formatter";

    runtimeInputs = [
      pkgs.stylua
      pkgs.alejandra
    ];

    text = ''
      alejandra .
      stylua .
    '';
  };
}
