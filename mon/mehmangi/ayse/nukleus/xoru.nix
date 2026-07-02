{ ... }:
{
  flake.nixosModules.ayse.nukleus.xoru =
  { ... }:
  {
    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
  };
}
