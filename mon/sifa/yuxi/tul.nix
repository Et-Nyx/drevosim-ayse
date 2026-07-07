{ ... }:
{
  flake.nixosModules.sifa.yuxi.tul =
  { pkgs, ... }:
  {
    environment.systemPackages = with pkgs; [
      gamescope # gamescope -W 1920 -H 1080 -r 60 -- %command%
      mangohud
      protonup-qt
      protontricks
    ];

    programs.gamemode = {
      enable = true;
    };
  };
}
