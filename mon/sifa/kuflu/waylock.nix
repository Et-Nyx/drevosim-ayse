{ lib, ... }:
{
  options.drevosim.kuflu.waylock = {
    enable = lib.mkEnableOption "waylock screen locker";
  };
}
