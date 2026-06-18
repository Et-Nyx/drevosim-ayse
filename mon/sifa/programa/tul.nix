{ ... }:
{
  flake.nixosModules.sifa.programa.tul =
  { pkgs, ... }:
  {
    environment.systemPackages = with pkgs; [
      wl-clipboard
    ];
  };
}
