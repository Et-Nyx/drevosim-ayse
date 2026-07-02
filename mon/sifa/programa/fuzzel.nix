{ lib, ... }:
{
  options.drevosim.programa.fuzzel = {
    enable = lib.mkEnableOption "fuzzel application launcher";
  };
}
