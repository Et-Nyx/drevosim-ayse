{ ... }:
{
  flake.nixosModules.sifa.servi.network =
  { ... }:
  {
    networking.networkmanager.enable = true;
  };
}
