{
	self,
	vimUtils,
	lib,
}:
vimUtils.buildVimPlugin {
  pname = "cpp-tools.nvim";
  version = self.shortRev or self.dirtyRev or "dirty";

  src = lib.fileset.toSource {
		root = ./.;
		fileset = lib.fileset.unions [
			./lua
		];
	};
}
