{ lib, ... }:
{
  options.drevosim.medya.tul = {
    enable = lib.mkEnableOption "simple media/brightness utilities" // {
      default = true;
    };
  };
}
