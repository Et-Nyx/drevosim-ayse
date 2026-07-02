{ lib, ... }:
{
  options.drevosim.servi.mako = {
    enable = lib.mkEnableOption "mako notification daemon";
  };
}
