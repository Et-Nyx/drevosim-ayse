{ lib, ... }:
{
  options.drevosim.kuflu.ly = {
    enable = lib.mkEnableOption "ly TUI display manager";
  };
}
