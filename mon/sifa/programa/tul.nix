{ lib, ... }:
{
  options.drevosim.programa.tul = {
    enable = lib.mkEnableOption "simple Wayland utilities" // {
      default = true;
    };
  };
}
