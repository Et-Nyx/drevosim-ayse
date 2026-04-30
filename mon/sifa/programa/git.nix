{ self, inputs, ... }:
{
  flake.nixosModules.git = 
  { pkgs, ... }:
  let
    misuGit = self.packages.${pkgs.stdenv.hostPlatform.system}.misuGit;
  in
  {
    programs.git = {
      enable = true;
      package = misuGit;
    };
  };
  perSystem =
  { pkgs, lib, ... }:
  {
    packages.misuGit = inputs.wrapper-modules.wrappers.git.wrap {
      inherit pkgs;
      settings = {
        user.email = lib.mkDefault "eter.nyx@proton.me";
	user.name = lib.mkDefault "ET";
	init.defaultBranch = "master";
      };
    };
  };
}
