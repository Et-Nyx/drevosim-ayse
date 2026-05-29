{ self, inputs, ... }:
{
  flake.nixosModules.brightnessctl =
    { pkgs, lib, config, ... }:
    let
      cfg = config.taluji.sifa.medya.brightnessctl;
    in
    {
      options.taluji.sifa.medya.brightnessctl = {
        enable = lib.mkEnableOption "Brightnessctl screen backlight utility";
      };
      config = lib.mkIf cfg.enable {
        environment.systemPackages = [ pkgs.brightnessctl ];
      };
    };
}
