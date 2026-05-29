{ self, inputs, ... }:
{
  flake.nixosModules.git =
    { pkgs, lib, config, ... }:
    let
      cfg = config.taluji.sifa.programa.git;
      misuGit = self.packages.${pkgs.stdenv.hostPlatform.system}.misuGit;
    in
    {
      options.taluji.sifa.programa.git = {
        enable = lib.mkEnableOption "Custom Git installation";
      };
      config = lib.mkIf cfg.enable {
        programs.git = {
          enable = true;
          package = misuGit;
        };
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
