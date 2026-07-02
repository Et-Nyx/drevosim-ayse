{ lib, ... }:
{
  flake.nixosModules.sifa.mesa.plasma =
  { config, pkgs, ... }:
  {
    options.drevosim.mesa.plasma = {
      enable = lib.mkEnableOption "KDE Plasma desktop" // {
        default = true;
      };
    };

    config = lib.mkIf config.drevosim.mesa.plasma.enable {
      # Plasma 6 defaults to a Wayland session.
      services.desktopManager.plasma6.enable = true;
      services.displayManager.defaultSession = "plasma";
      services.displayManager.sddm = {
        enable = true;
        wayland.enable = true;
      };
      xdg.portal = {
        enable = true;
        extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
      };
    };
  };
}
