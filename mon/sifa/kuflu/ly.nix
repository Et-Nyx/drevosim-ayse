{ self, inputs, ... }:
{
  flake.nixosModules.ly =
    { pkgs, lib, config, ... }:
    let
      cfg = config.taluji.sifa.kuflu.ly;
    in
    {
      options.taluji.sifa.kuflu.ly = {
        enable = lib.mkEnableOption "Ly Display Manager service";
      };
      config = lib.mkIf cfg.enable {
        services.displayManager.ly = {
          enable = true;
          settings = {
            animation = "matrix";
            hide_borders = false;
          };
        };
      };
    };
}
