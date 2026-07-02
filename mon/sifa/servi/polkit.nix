{ lib, ... }:
{
  options.drevosim.servi.polkit = {
    enable = lib.mkEnableOption "Polkit authentication agent";
  };
}
