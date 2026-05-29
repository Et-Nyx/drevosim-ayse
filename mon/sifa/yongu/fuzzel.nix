{ self, inputs, ... }:
{
  flake.nixosModules.fuzzel =
    { pkgs, lib, config, ... }:
    let
      cfg = config.taluji.sifa.yongu.fuzzel;
      misuFuzzel = self.packages.${pkgs.stdenv.hostPlatform.system}.misuFuzzel;
    in
    {
      options.taluji.sifa.yongu.fuzzel = {
        enable = lib.mkEnableOption "Fuzzel application launcher";
      };
      config = lib.mkIf cfg.enable {
        environment.systemPackages = [ misuFuzzel ];
        environment.sessionVariables.FUZZEL_LAUNCHER = "${misuFuzzel}/bin/fuzzel";
      };
    };
  perSystem = { pkgs, ... }:
  {
    packages.misuFuzzel = inputs.wrapper-modules.wrappers.fuzzel.wrap {
      inherit pkgs;
      settings = {
        main = {
          font = "monospace:size=12";
          dpi-aware = "auto";
          icons-enabled = "yes";
          match-mode = "fzf";
        };
      };
    };
  };
}
