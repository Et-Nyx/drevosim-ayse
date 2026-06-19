{ ... }:
{
  flake.nixosModules.sifa.servi.polkit =
  { config, lib, pkgs, ... }:
  let
    cfg = config.drevosim.servi.polkit;
    agent = pkgs.polkit_gnome;
    agentBin = "${agent}/libexec/polkit-gnome-authentication-agent-1";
  in
  {
    options.drevosim.servi.polkit = {
      enable = lib.mkEnableOption "graphical polkit authentication agent";
    };

    config = lib.mkIf cfg.enable {
      security.polkit.enable = true;
      environment.systemPackages = [ agent ];
      drevosim.mesa.river.awto = lib.mkIf config.drevosim.mesa.river.enable [
        agentBin
      ];
    };
  };
}
