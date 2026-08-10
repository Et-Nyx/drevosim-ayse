{ ... }:
{
  flake.nixosModules.sifa.programa.tul =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        chromium
        opencode
        wget
        fastfetch
        browsh
        beeper
        proton-vpn
        grayjay
      ];
    };
}
