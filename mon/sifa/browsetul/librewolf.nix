{ self, inputs, ... }:
{
  flake.nixosModules.librewolf =
  { pkgs, lib, ... }:
  {
    environment.systemPackages = [ pkgs.librewolf ];
  };
}
