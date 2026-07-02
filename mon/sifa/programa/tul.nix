{ ... }:
{
  flake.nixosModules.sifa.programa.tul =
  { pkgs, ... }:
  {
    environment.systemPackages = with pkgs; [
      chromium
      ladybird
      opencode
      wget
    ];
  };
}
