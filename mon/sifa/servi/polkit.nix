{ ... }:
{
  flake.nixosModules.sifa.servi.polkit =
  { config, lib, pkgs, ... }:
  let
    cfg = config.drevosim.servi.polkit;
  in
  {
    options.drevosim.servi.polkit = {
      enable = lib.mkEnableOption "polkit authentication agent";
    };

    config = lib.mkIf cfg.enable {
      security.polkit.enable = true;
      environment.systemPackages = [ pkgs.polkit_gnome ];
      drevosim.session.autostart = [
        "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
      ];
    };
  };
}
