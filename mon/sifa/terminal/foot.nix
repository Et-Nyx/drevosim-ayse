{ lib, ... }:
{
  options.drevosim.terminal.foot = {
    enable = lib.mkEnableOption "foot terminal";
  };
}
