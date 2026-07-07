{ ... }:
{
  flake.nixosModules.sifa.yuxi.heroic =
  { config, lib, pkgs, ... }:
  let
    opsyon = config.drevosim.yuxi.heroic;
  in
  {
    options.drevosim.yuxi.heroic = {
      enable = lib.mkEnableOption "heroic game launcher" // {
        default = true;
      };
    };

    config = lib.mkIf opsyon.enable {
      environment.systemPackages = with pkgs; [
        heroic
      ];
    };
  };
}
