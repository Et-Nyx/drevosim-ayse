{ lib, ... }:
{
  options.drevosim.kuflu.swaylock = {
    enable = lib.mkEnableOption "swaylock screen locker";
  };
}
