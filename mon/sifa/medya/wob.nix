{ self, inputs, ... }:
{
  flake.nixosModules.wob =
    { pkgs, lib, config, ... }:
    let
      cfg = config.taluji.sifa.medya.wob;
    in
    {
      options.taluji.sifa.medya.wob = {
        enable = lib.mkEnableOption "Wob overlay bar for Wayland volume/backlight feedback";
      };
      config = lib.mkIf cfg.enable {
        environment.systemPackages = [ pkgs.wob ];
      };
    };
}
