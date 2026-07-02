{ lib, ... }:
{
  flake.nixosModules.sifa.servi.mako =
  { config, ... }:
  {
    options.drevosim.servi.mako = {
      enable = lib.mkEnableOption "mako notification daemon" // {
        default = true;
      };
    };

    config = lib.mkIf config.drevosim.servi.mako.enable {
      # Real mako config will go here.
    };
  };
}
