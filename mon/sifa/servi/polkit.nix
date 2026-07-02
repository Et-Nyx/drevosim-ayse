{ lib, ... }:
{
  flake.nixosModules.sifa.servi.polkit =
  { config, ... }:
  {
    options.drevosim.servi.polkit = {
      enable = lib.mkEnableOption "Polkit authentication agent" // {
        default = true;
      };
    };

    config = lib.mkIf config.drevosim.servi.polkit.enable {
      # Real polkit config will go here.
    };
  };
}
