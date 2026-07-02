{ lib, ... }:
{
  flake.nixosModules.sifa.programa.fuzzel =
  { config, ... }:
  {
    options.drevosim.programa.fuzzel = {
      enable = lib.mkEnableOption "fuzzel application launcher" // {
        default = true;
      };
    };

    config = lib.mkIf config.drevosim.programa.fuzzel.enable {
      # Real fuzzel config will go here.
    };
  };
}
