{ lib, ... }:
{
  flake.nixosModules.sifa.kuflu.waylock =
  { config, ... }:
  {
    options.drevosim.kuflu.waylock = {
      enable = lib.mkEnableOption "waylock screen locker" // {
        default = true;
      };
    };

    config = lib.mkIf config.drevosim.kuflu.waylock.enable {
      # Real waylock config will go here.
    };
  };
}
