{ lib, ... }:
{
  flake.nixosModules.sifa.kuflu.swaylock =
  { config, ... }:
  {
    options.drevosim.kuflu.swaylock = {
      enable = lib.mkEnableOption "swaylock screen locker" // {
        default = true;
      };
    };

    config = lib.mkIf config.drevosim.kuflu.swaylock.enable {
      # Real swaylock config will go here.
    };
  };
}
