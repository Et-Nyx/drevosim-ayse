{ ... }:
{
  flake.nixosModules.sifa.yuxi.steam =
  { config, lib, ... }:
  let
    opsyon = config.drevosim.yuxi.steam;
  in
  {
    options.drevosim.yuxi.steam = {
      enable = lib.mkEnableOption "steam game launcher" // {
        default = true;
      };
    };

    config = lib.mkIf opsyon.enable {
      programs.steam = {
        enable = true;
        gamescopeSession.enable = true;
        remotePlay.openFirewall = true;
      };
    };
  };
}
