{ self, inputs, ... }:
{
  flake.nixosModules.tlp =
    { pkgs, lib, config, ... }:
    let
      cfg = config.taluji.sifa.servi.tlp;
    in
    {
      options.taluji.sifa.servi.tlp = {
        enable = lib.mkEnableOption "TLP power management service";
      };
      config = lib.mkIf cfg.enable {
        services.tlp.enable = true;
      };
    };
}
