{ ... }:
{
  flake.nixosModules.ayse.ogarli =
  { ... }:
  {
    users.users.eter = {
      isNormalUser = true;
      initialPassword = "1234";
      useDefaultShell = true;
      extraGroups = [
        "wheel"
        "networkmanager"
        "libvirtd"
      ];
      packages = [ ];
    };
  };
}
