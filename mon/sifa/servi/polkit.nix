{ ... }:
{
  flake.nixosModules.sifa.servi.polkit =
  { config, lib, pkgs, ... }:
  let
    cfg = config.drevosim.servi.polkit;
  in
  {
    options.drevosim.servi.polkit = {
      enable = lib.mkEnableOption "graphical polkit authentication agent";
    };

    config = lib.mkIf cfg.enable {
      security.polkit.enable = true;
      environment.systemPackages = [ pkgs.kdePackages.polkit-kde-agent-1 ];
      drevosim.session.autostart = [
        "${pkgs.kdePackages.polkit-kde-agent-1}/libexec/polkit-kde-authentication-agent-1"
      ];
    };
  };
}
