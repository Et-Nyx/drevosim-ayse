{ lib, ... }:
{
  flake.nixosModules.sifa.mesa.plasma =
  { config, ... }:
  {
    options.drevosim.mesa.plasma = {
      enable = lib.mkEnableOption "KDE Plasma desktop" // {
        default = true;
      };
    };

    config = lib.mkIf config.drevosim.mesa.plasma.enable {
      services.desktopManager.plasma6.enable = true;
      services.displayManager.sddm.enable = true;
      services.displayManager.defaultSession = "plasma";
    };
  };
}
