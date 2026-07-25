{ ... }:
{
  flake.nixosModules.sifa.programa.waydroid =
  { ... }:
  {
    virtualisation.waydroid = {
      enable = true;
    };
  };
}
