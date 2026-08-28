{ ... }:
{
  flake.nixosModules.sifa.medya.tul =
  { pkgs, ... }:
  {
    environment.systemPackages = with pkgs; [
      brightnessctl
      playerctl
      ffmpeg
      stremio-service
      krita
      rPackages.hermes
    ];
  };
}
