{ self, inputs, ... }:
{
  flake.nixosModules.bluetooth =
    { pkgs, lib, config, ... }:
    let
      cfg = config.taluji.sifa.servi.bluetooth;
    in
    {
      options.taluji.sifa.servi.bluetooth = {
        enable = lib.mkEnableOption "Bluetooth system services (BlueZ)";
      };
      config = lib.mkIf cfg.enable {
        hardware.bluetooth = {
          enable = true;
          powerOnBoot = true;
          settings = {
            General = {
              Experimental = true;
              FastConnectable = true;
            };
            Policy = {
              AutoEnable = true;
            };
          };
        };
      };
    };
}
