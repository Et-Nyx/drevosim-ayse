{ ... }:
{
  flake.nixosModules.sifa.servi.networkmanager =
  { ... }:
  {
    networking.networkmanager.enable = true;
  };
}
